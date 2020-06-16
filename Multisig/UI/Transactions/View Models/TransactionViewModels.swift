//
//  TransactionModels.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation



/*

     func transfers(from tx: Transaction, _ info: SafeStatusRequest.Response) -> [BaseTransactionViewModel] {
         var result: [BaseTransactionViewModel] = []

         if tx.transfers?.isEmpty ?? true {
             if tx.data != nil {
                 result.append(customTransaction(from: tx, info))
             }
             else {
                 result.append(multisigTx(from: tx, info))
             }
         }
         else {
             for transfer in tx.transfers! {
                 let transaction: TransferTransaction

                 let value: String?, tokenAddress: String?
                 switch transfer.type {
                 case .ether:
                     transaction = TransferTransaction()
                     value = transfer.value
                     tokenAddress = nil
                 case .erc20:
                     transaction = TransferTransaction()
                     value = transfer.value
                     tokenAddress = transfer.tokenAddress
                 case .erc721:
                     transaction = TransferTransaction()
                     value = "1"
                     tokenAddress = transfer.tokenAddress
                 case .unknown:
                     let custom = CustomTransaction()
                     custom.dataLength = tx.data.map { Data(hex: $0).count } ?? 0
                     transaction = custom
                     value = transfer.value
                     tokenAddress = nil
                 }

                 if transfer.to == info.address {
                     transaction.address = transfer.from ?? "Unknown"
                     transaction.isOutgoing = false
                 }
                 else {
                     transaction.address = transfer.to ?? "Unknown"
                     transaction.isOutgoing = true
                 }

                 (transaction.amount, transaction.tokenSymbol) = formattedAmount(value, tokenAddress, isNegative: transaction.isOutgoing)

                 let dateFormatter = DateFormatter()
                 dateFormatter.locale = .autoupdatingCurrent
                 dateFormatter.dateStyle = .medium
                 dateFormatter.timeStyle = .medium

                 transaction.date = transfer.executionDate ?? tx.executionDate ?? tx.submissionDate ?? tx.modified
                 assert(transaction.date != nil)
                 transaction.formattedDate = transaction.date.map { dateFormatter.string(from: $0) } ?? ""

                 transaction.confirmationCount = transaction.confirmationCount
                 transaction.nonce = tx.nonce.map { String($0) }
                 transaction.threshold = tx.confirmationsRequired

                 transaction.status = .success

                 result.append(transaction)
             }
         }

         return result
     }

     func formattedAmount(_ value: String?, _ tokenAddress: String?, isNegative: Bool) -> (amount: String, symbol: String) {
         let formatter = TokenFormatter()
         let tokenAddress = tokenAddress ?? Address.zero.hex(eip55: true)
         let token = App.shared.tokenRegistry[tokenAddress]

         return (formatter.safeString(from: value, decimals: token?.decimals ?? 0, isNegative: isNegative, forcePlusSign: true), token?.symbol ?? "")
     }

     func multisigTx(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel {
         ethTransaction(from: tx, info) ??
         erc20Transaction(from: tx, info) ??
         erc721Transaction(from: tx, info) ??
         settingTransaction(from: tx, info) ??
         customTransaction(from: tx, info)
     }

     func updateBaseFields(in model: BaseTransactionViewModel, from tx: Transaction, info: SafeStatusRequest.Response) {
         model.nonce = tx.nonce.map { String($0) }
         model.status = tx.status(safeNonce: info.nonce, safeThreshold: info.threshold)
         model.confirmationCount = tx.confirmations?.count
         model.threshold = tx.confirmationsRequired

         let dateFormatter = DateFormatter()
         dateFormatter.locale = .autoupdatingCurrent
         dateFormatter.dateStyle = .medium
         dateFormatter.timeStyle = .medium

         model.date = tx.executionDate ?? tx.submissionDate ?? tx.modified
         assert(model.date != nil)
         model.formattedDate = model.date.map { dateFormatter.string(from: $0) } ?? ""
     }

     func ethTransaction(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel? {
         guard
             tx.data == nil,
             tx.operation == 0,
             let to = tx.to
             else { return nil }
         let result = TransferTransaction()
         result.isOutgoing = true
         result.address = to
         (result.amount, result.tokenSymbol) = formattedAmount(tx.value, nil, isNegative: result.isOutgoing)
         updateBaseFields(in: result, from: tx, info: info)
         return result
     }

     enum ERC20Methods: String {
         case transfer
         case transferFrom
     }

     func erc20Transaction(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel? {
         guard tx.data != nil,
             tx.operation == 0,
             let decodedData = tx.dataDecoded,
             let method = ERC20Methods(rawValue: decodedData.method),
             let safe = tx.safe,
             let tokenAddress = tx.to
             else { return nil }

         let to: String, from: String, amount: String

         switch method {
         case .transfer:
             guard decodedData.parameters.count == 2,
                 decodedData.parameters[0].type == "address",
                 decodedData.parameters[1].type == "uint256" else {
                     return nil
             }
             to = decodedData.parameters[0].value
             from = tx.safe ?? info.address
             amount = decodedData.parameters[1].value
         case .transferFrom:
             guard decodedData.parameters.count == 3,
                 decodedData.parameters[0].type == "address",
                 decodedData.parameters[1].type == "address",
                 decodedData.parameters[2].type == "uint256" else {
                     return nil
             }
             from = decodedData.parameters[0].value
             to = decodedData.parameters[1].value
             amount = decodedData.parameters[2].value
         }

         let result = TransferTransaction()
         result.isOutgoing = from == safe
         result.address = result.isOutgoing ? to : from
         (result.amount, result.tokenSymbol) = formattedAmount(amount, tokenAddress, isNegative: result.isOutgoing)
         updateBaseFields(in: result, from: tx, info: info)
         return result
     }

     enum ERC721Methods: String {
         case safeTransferFrom
 //        case transferFrom
     }

     func erc721Transaction(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel? {
         guard tx.data != nil,
             tx.operation == 0,
             let decodedData = tx.dataDecoded,
             let _ = ERC721Methods(rawValue: decodedData.method),
             let safe = tx.safe,
             let tokenAddress = tx.to
             else { return nil }

         let to: String, from: String, amount: String

         guard decodedData.parameters.count >= 3,
             decodedData.parameters[0].type == "address",
             decodedData.parameters[1].type == "address",
             decodedData.parameters[2].type == "uint256" else {
                 return nil
         }
         from = decodedData.parameters[0].value
         to = decodedData.parameters[1].value
         amount = "1"

         let result = TransferTransaction()
         result.isOutgoing = from == safe
         result.address = result.isOutgoing ? to : from
         (result.amount, result.tokenSymbol) = formattedAmount(amount, tokenAddress, isNegative: result.isOutgoing)
         updateBaseFields(in: result, from: tx, info: info)
         return result
     }

     enum SafeSettingMethods: String {
         case setFallbackHandler
         case addOwnerWithThreshold
         case removeOwner
         case swapOwner
         case changeThreshold
         case enableModule
         case disableModule
         case changeMasterCopy
     }

     func settingTransaction(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel? {
         guard
             tx.data != nil,
             let to = tx.to, to == info.address,
             tx.operation == 0,
             let decodedData = tx.dataDecoded,
             let method = SafeSettingMethods(rawValue: decodedData.method)
             else { return nil }

         if method == .changeMasterCopy {
             let result = ChangeMasterCopyTransaction()
             let address = decodedData.parameters.first.flatMap { Address($0.value) } ?? Address.zero
             result.contractAddress = address.hex(eip55: true)
             result.contractVersion = GnosisSafe().versionNumber(masterCopy: address) ?? "Unknown"
             updateBaseFields(in: result, from: tx, info: info)
             return result
         } else {
             let result = SettingChangeTransaction()
             result.title = method.rawValue
             updateBaseFields(in: result, from: tx, info: info)
             return result
         }
     }

     func customTransaction(from tx: Transaction, _ info: SafeStatusRequest.Response) -> BaseTransactionViewModel {
         let result = CustomTransaction()
         result.isOutgoing = true
         result.address = tx.to ?? Address.zero.hex(eip55: true)
         (result.amount, result.tokenSymbol) = formattedAmount(tx.value, nil, isNegative: result.isOutgoing)
         result.dataLength = tx.data.map { Data(hex: $0).count } ?? 0
         updateBaseFields(in: result, from: tx, info: info)
         return result
     }

 */
