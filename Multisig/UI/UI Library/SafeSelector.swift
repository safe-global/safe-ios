//
//  SafeSelector.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeSelector: View {
    var height: CGFloat = 116
    
    @FetchRequest(fetchRequest: AppSettings.settings()) var appSettings: FetchedResults<AppSettings>
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    @Binding var showSheet: Bool
    @Binding var activeSheet: SafeSelectorActiveOption
    
    var body: some View {
        var safe: Safe?
        if let address = appSettings[0].selectedSafe {
            safe = try? context.fetch(Safe.by(address: address)).first
        }
        
        return HStack (alignment: .center, spacing: 0) {
            if safe == nil {
                Image("safe-selector-not-selected-icon")
                    .padding()
                Text("No Safe loaded")
                    .font(Font.gnoBody.weight(.semibold))
                    .foregroundColor(Color.gnoMediumGrey)
                Spacer()
                
            }
            else {
                Button(action: {
                    self.showSheet.toggle()
                    self.activeSheet = .info
                }) {
                    HStack {
                        Identicon(safe?.address ?? "").frame(width: 36, height: 36)
                            .padding()
                        VStack (alignment: .leading){
                            Text(safe?.name ?? "")
                            .font(Font.gnoBody.weight(.medium))
                            .multilineTextAlignment(.center)

                            ShortAddressText(safe?.address ?? "")
                            .multilineTextAlignment(.center)
                        }.foregroundColor(Color.gnoDarkBlue)
                    }
                }
                Spacer()
                Button(action: {
                    self.activeSheet = .switchSafe
                    self.showSheet.toggle()
                }) {
                    Image("ico-circle-down")
                    }.foregroundColor(.gnoMediumGrey).frame(width: 20, height: 20).padding()
            }
            
        }.frame(height: height, alignment: .bottom)
        .background(
            Rectangle()
                .foregroundColor(Color.gnoSnowwhite)
                .cardShadowTooltip()
        )
    }
}

enum SafeSelectorActiveOption {
    case info, switchSafe, none
}

struct SafeSelector_Previews: PreviewProvider {
    static var previews: some View {
//        let context = TestCoreDataStack().persistentContainer.viewContext
//        let safe = Safe(context: context)
//        safe.name = "Safe \(i)"
//        safe.address = "0x\(i)"
        return SafeSelector(showSheet: .constant(false), activeSheet: .constant(.info))
            //.environment(\.managedObjectContext, context)
    }
}
