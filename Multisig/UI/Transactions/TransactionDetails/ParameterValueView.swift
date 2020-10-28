//
//  ParameterValueView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ParameterValueView: View {
    var type: String
    var value: DataDecodedParameterValue?
    var nestingLevel: Int = 0

    var body: some View {
        valueView.padding(.leading, nestingLevel == 0 ? 0 : 8)
    }

    @ViewBuilder
    var valueView: some View {
        if let address = value?.addressValue {
            AddressCell(address: address.checksummed)
        } else if let string = stringValue {
            if type.starts(with: "bytes"), let data = value?.dataValue {
                ExpandableButton(title: "\(data.count) bytes", value: string)
            } else {
                Text(string).body(.gnoDarkGrey)
            }
        } else {
            ExpandableView(title: Text("array").body(.gnoDarkGrey),
                           value: arrayContent)
        }
    }

    var arrayContent: some View {
        ForEach((0..<value!.arrayValue!.count)) { index in
            ParameterValueView(type: type,
                               value: self.value!.arrayValue![index],
                               nestingLevel: self.nestingLevel + 1)
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
            ParameterValueView(type: "String", value: ["Hello","Hello", "Hello", ["Hello", "Hello"]])
        }
    }
}

