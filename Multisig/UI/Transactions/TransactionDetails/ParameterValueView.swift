//
//  ParameterValueView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ParameterValueView: View {
    var value: DataDecodedParameterValue?
    var nestingLevel: Int = 0

    var body: some View {
        VStack {
            if nestingLevel > 9 {
                Text("some value")
            } else {
                valueView.padding(.leading, CGFloat(nestingLevel) * 8)
            }
        }
    }

    @ViewBuilder
    var valueView: some View {
        if value?.addressValue != nil {
            AddressCell(address: value!.addressValue!.checksummed)
        } else if stringValue != nil {
            Text(stringValue!).body(.gnoDarkGrey)
        } else {
            VStack(alignment: .leading) {
                Text("array").body(.gnoDarkGrey)
                ForEach((0..<value!.arrayValue!.count)) { index in
                    ParameterValueView(value: self.value!.arrayValue![index],
                                       nestingLevel: self.nestingLevel + 1)
                }
            }
        }
    }

    var stringValue: String? {
        guard let value = value else { return "-" }
        if value.arrayValue == nil && value.stringValue == nil {
            return "Unsupported type of value"
        } else if let array = value.arrayValue, array.isEmpty {
            return "empty"
        }

        return value.stringValue
    }
}

struct ParameterValueView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ParameterValueView(value: ["Hello","Hello", "Hello", ["Hello", "Hello"]])
        }
    }
}
