//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Node {
    // NOTE: https://eips.ethereum.org/EIPS/eip-2681 for using uint64 for transaction count
    public class eth_getTransactionCount: NodeAccountMethod<NodeQuantity<Sol.UInt64>>  {}
    public class eth_getBalance: NodeAccountMethod<NodeQuantity<Sol.UInt256>>  {}
    public class eth_getCode: NodeAccountMethod<NodeData<Data>>  {}

    public class eth_call: NodeMessageCallMethod<NodeData<Data>> {}
    public class eth_estimateGas: NodeMessageCallMethod<NodeQuantity<Sol.UInt256>> {}

}
