//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation

func wrap<T>(completion: @escaping (Result<T, Error>) -> Void) -> (Result<NodeQuantity<T>, Error>) -> Void where T: FixedWidthInteger {
    { result in
        let newResult = result.map { quantity -> T in
            quantity.value
        }
        completion(newResult)
    }
}

func wrap<T>(completion: @escaping (Result<T, Error>) -> Void) -> (Result<NodeData<T>, Error>) -> Void where T: NodeDataCodable {
    { result in
        let newResult = result.map { quantity -> T in
            quantity.value
        }
        completion(newResult)
    }
}
