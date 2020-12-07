//
//  ParameterView.swift
//  Multisig
//
//  Created by Moaaz on 8/21/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ParameterView: View {
    let parameter: DataDecodedParameter
    var body: some View {
        VStack (alignment: .leading, spacing: 6) {
            Text("\(parameter.name)(\(parameter.type)):").body()
            ParameterValueView(type: parameter.type, value: parameter.value)
        }
    }
}

struct ParameterViewV2: View {
    let parameter: SCG.DataDecoded.Parameter
    var body: some View {
        VStack (alignment: .leading, spacing: 6) {
            Text("\(parameter.name)(\(parameter.type)):").body()
            ParameterValueViewV2(type: parameter.type, value: parameter.value)
        }
    }
}
