//
//  SafeAddressForm.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

enum SafeAddressFormError: Error {
    case safeNotFound
    case validationFailed(String)
}

extension SafeAddressFormError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .safeNotFound:
            return "Failed to find a safe at the address. Please try another address."
        case .validationFailed(let reason):
            return "Failed to validate address: \(reason)"
        }
    }
}

class SafeAddressFormModel: ObservableObject {

    // when address is entered in the address field,
    // then we check that the safe exists.
    // if it doesn't exist, then address cannot be used.

    @Published
    var error: String?

    @Published
    var address: Address?

    @Published
    var isValidating: Bool = false

    @Published
    var canProceed: Bool = false

    var addressFieldModel = AddressFieldModel()

    private var publishers = Set<AnyCancellable>()

    init() {
        addressFieldModel.$address
        .dropFirst()
        .filter { $0 != nil}
        .compactMap { [weak self] address -> Address? in
            self?.error = nil
            self?.canProceed = false
            self?.isValidating = true
            return address
        }
        .flatMap { address in
            Just(address)
            .receive(on: DispatchQueue.global())
            .tryMap { address in
                let exists = try Safe.exists(at: address)
                if exists { return address }
                throw SafeAddressFormError.safeNotFound
            }
            .mapError { error -> SafeAddressFormError in
                if let error = error as? SafeAddressFormError { return error }

                if case let HTTPClient.Error.networkRequestFailed(request, response, data) = error {

                    var body: String
                    if let data = data, let string = String(data: data, encoding: .utf8) {
                        body = string
                    } else {
                        body = "<no response body>"
                    }

                    var responseString: String
                    if let response = response {
                        responseString = String(describing: response)
                    } else {
                        responseString = "<no response>"
                    }

                    let reason = ["Request failed", String(describing: request), responseString, body].joined(separator: "\n\n")
                    return SafeAddressFormError.validationFailed(reason)
                }
                return SafeAddressFormError.validationFailed(String(describing: error))
            }
            .receive(on: RunLoop.main)
            .catch { [weak self] error -> Just<Address?> in
                self?.error = error.localizedDescription
                return .init(nil)
            }
        }
        .sink { [weak self] address in
            self?.address = address
            self?.canProceed = address != nil
            self?.isValidating = false
        }
        .store(in: &publishers)
    }

}

struct SafeAddressForm: View {

    @ObservedObject
    var model = SafeAddressFormModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                Text("Enter your Safe Multisig address.")
                    .font(Font.gnoBody.weight(.medium))
                    .padding(.top, 8)
                    .padding(.bottom, 24)

                AddressField(model: model.addressFieldModel)

                text(
                    "Don't have a Safe? Create one first at",
                    link: "https://gnosis-safe.io"
                )
                .padding([.top, .bottom], 18)

                if $model.isValidating.wrappedValue {
                    HStack {
                        Text("Validating...")
                            .font(Font.gnoBody.weight(.medium))
                            .foregroundColor(.gnoDarkBlue)

                        ActivityIndicator(isAnimating: .constant(true),
                                          style: .medium)
                    }
                }

                if $model.error.wrappedValue != nil {

                    ScrollView {
                        Text($model.error.wrappedValue!)
                            .font(Font.system(size: 12,
                                              weight: .semibold,
                                              design: .monospaced))
                            .foregroundColor(.gnoDarkBlue)
                    }
                } else if $model.canProceed.wrappedValue {

                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: 32)
                            .foregroundColor(.gnoHold)

                        Text("Safe found.")
                            .font(Font.gnoBody.weight(.medium))
                    }

                }

                Spacer()
            }
            .foregroundColor(.gnoDarkBlue)
            .padding()
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(leading: backButton, trailing: nextButton)
        }
    }

    var title: Text {
        Text("Load Safe Multisig")
            .font(Font.gnoBody.weight(.semibold))
            .foregroundColor(.gnoDarkBlue)
    }

    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>

    var backButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
        .accentColor(.gnoHold)
    }

    var nextButton: some View {
        NavigationLink(destination: EnterSafeNameView()) {
            Text("Next")
                .fontWeight(.semibold)
        }
        .accentColor(.gnoHold)
        .disabled(!$model.canProceed.wrappedValue)
    }

    @State private var showsLink = false

    func text(_ text: String,
              link: String) -> some View {
        VStack(spacing: 0) {
            Text(text)
                .foregroundColor(.gnoDarkBlue)

            Button(action: {
                self.showsLink = true
            }) {
                HStack(spacing: 4) {
                    Text(link)
                    Image("icon-external-link")
                }.foregroundColor(.gnoHold)
            }
        }
        .font(Font.gnoBody.weight(.medium))
        .sheet(isPresented: self.$showsLink) {
            SafariViewController(url: URL(string: link)!)
        }
    }
}

struct SafeAddressForm_Previews: PreviewProvider {
    static var previews: some View {
        SafeAddressForm()
    }
}

import UIKit
struct ActivityIndicator: UIViewRepresentable {

    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}
