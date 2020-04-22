//
//  AddressField.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

enum ValidationError: Error {
    case empty
}

extension ValidationError: LocalizedError {

    var errorDescription: String? {
        "The value is empty"
    }
}

class AddressFieldModel: ObservableObject {

    @Published
    var enteredText: String?

    @Published
    var displayedText: String?

    @Published
    var errorMessages: [String] = []

    @Published
    var isWithoutErrors: Bool = true

    @Published
    var address: Address?

    private var publishers = Set<AnyCancellable>()

    init() {
        $enteredText
        .map { [unowned self] in
            self.errorMessages = []
            self.displayedText = nil
            self.address = nil
            self.isWithoutErrors = true
            return $0?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .flatMap { [unowned self] in
            Just($0)
                .tryMap(self.isEmpty)
                .tryMap(self.toAddress)
                .catch { error -> Just<String?> in
                    self.errorMessages = [error.localizedDescription]
                    return .init(self.enteredText)
            }
        }
        .sink { [unowned self] in
            self.displayedText = $0
            self.isWithoutErrors = self.errorMessages.isEmpty
        }
        .store(in: &publishers)
    }

    func isEmpty(_ text: String?) throws -> String? {
        guard let value = text, value.isEmpty else { return text }
        throw ValidationError.empty
    }

    func toAddress(_ text: String?) throws -> String? {
        guard let input = text else { return text }
        // We don't check for eip55 because we might get non-formatted
        // address from the user.
        address = try Address(hex: input, eip55: false)
        let output = address!.hex(eip55: true)
        return output
    }
}

enum UIMetric {
    static let fieldMinHeight: CGFloat = 56
    static let cornerRadius: CGFloat = 10
    static let borderWidth: CGFloat = 2
}

struct AddressField: View {

    var placeholder: String? = "Enter Safe address"

    @State private var showsSheet: Bool = false

    @ObservedObject
    var model = AddressFieldModel()

    var body: some View {
        VStack(alignment: .leading) {
            AddressInputSourceSheet(text: $model.enteredText,
                                    isPresented: $showsSheet)

            Button(action: { self.showsSheet.toggle() }) {

                return Frame(isValid: $model.isWithoutErrors.wrappedValue) {

                    Group {
                        // nothing entered
                        if $model.displayedText.wrappedValue == nil {

                            Text(placeholder ?? "").font(.gnoCallout)

                        // entered address
                        } else if $model.isWithoutErrors.wrappedValue {

                            AddressView($model.displayedText.wrappedValue!)

                        // entered some other text
                        } else {

                            Text($model.displayedText.wrappedValue!)
                                .lineLimit(3)
                                .font(Font.gnoCallout.weight(.medium))
                                .foregroundColor(.gnoDarkBlue)

                        }
                    }.padding()

                }
            }

            ForEach($model.errorMessages.wrappedValue, id: \.self) { error in
                Text(error)
                    .font(.gnoCallout)
                    .foregroundColor(.gnoTomato)
            }
        }
    }

    struct Frame<Content>: View where Content: View {
        private let content: Content
        private var isValid: Bool

        init(isValid: Bool, @ViewBuilder content: () -> Content) {
            self.isValid = isValid
            self.content = content()
        }

        var body: some View {
            HStack {
                content

                Spacer()

                Image(systemName: "ellipsis")
                    .padding()
            }
            .foregroundColor(Color.gnoMediumGrey)
            .background(
                RoundedRectangle(cornerRadius: UIMetric.cornerRadius)
                    .stroke(isValid ? Color.gnoWhitesmoke : .gnoTomato,
                            lineWidth: UIMetric.borderWidth)
            )
                .frame(minHeight: UIMetric.fieldMinHeight)
        }
    }

}

struct AddressField_Previews: PreviewProvider {
    static var previews: some View {
            NavigationView {
                VStack {
                    AddressField()
                    .padding()
                }.navigationBarTitle("Title")
        }
    }
}
