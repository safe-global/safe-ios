//
//  NetworkContentViewModel.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 15.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

protocol LoadingModel: AnyObject {
    associatedtype ResultType
    var status: ViewLoadingStatus { get set }
    var result: ResultType { get set }
    var reloadSubject: PassthroughSubject<Void, Never> { get set }
    var cancellables: Set<AnyCancellable> { get set }
    var coreDataCancellable: AnyCancellable? { get set }

    func buildReload()
}

extension LoadingModel {
    func buildCoreDataPipeline() {
        coreDataCancellable =
            Publishers
            .onCoreDataSave
            .sink { [weak self] _ in
                guard let `self` = self else { return }
                self.cancellables = .init()
                self.reloadSubject = .init()
                self.status = .initial
                self.buildReload()
            }
    }

    func buildReloadPipelineWith<Failure>(loadData: (AnyPublisher<Void, Never>) -> AnyPublisher<ResultType, Failure>) {
        reloadSubject
            .status(.loading, path: \.status, object: self, set: &cancellables)

        let outputFork =
            loadData(reloadSubject.eraseToAnyPublisher())
            .transformToResult()
            .multicast { PassthroughSubject<Result<ResultType, Failure>, Never>() }

        outputFork
            .onSuccessResult()
            .assign(to: \.result, on: self)
            .store(in: &cancellables)

        outputFork
            .onSuccessResult()
            .status(.success, path: \.status, object: self, set: &cancellables)

        outputFork
            .handleError(statusPath: \.status, object: self, set: &cancellables)

        outputFork
            .connect()
            .store(in: &cancellables)
    }

    func reload() {
        self.cancellables = .init()
        self.reloadSubject = .init()
        self.buildReload()
        reloadSubject.send()
    }
}

extension Publisher {
    func selectedSafe() -> AnyPublisher<Safe, Error> {
        self
            .tryCompactMap { _ -> Safe? in
                let context = App.shared.coreDataStack.viewContext
                let fr = Safe.fetchRequest().selected()
                let safe = try context.fetch(fr).first
                return safe
            }
            .eraseToAnyPublisher()
    }

    func safeToAddress() -> AnyPublisher<Address, Error> where Output == Safe {
        self
            .tryCompactMap { safe in
                guard let address = safe.address else { return nil }
                return try Address(from: address)
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func transformToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self
            .map { value -> Result<Output, Failure> in .success(value) }
            .catch { error in
                Just(.failure(error))
            }
            .eraseToAnyPublisher()
    }
}

// Result<K, Failure>
extension Publisher {
    func handleError<Root, Success, Failed>(statusPath:  ReferenceWritableKeyPath<Root, ViewLoadingStatus>, object: Root, set: inout Set<AnyCancellable>) where Output == Result<Success, Failed>, Failure == Never {
        self
            .onFailedResult()
            .map { error -> Void in
                App.shared.snackbar.show(message: error.localizedDescription)
            }
            .status(.failure, path: statusPath, object: object, set: &set)
    }

    func status<Root>(_ status: ViewLoadingStatus, path: ReferenceWritableKeyPath<Root, ViewLoadingStatus>, object: Root, set: inout Set<AnyCancellable>) where Failure == Never {
        self
            .map { _ -> ViewLoadingStatus in status }
            .assign(to: path, on: object)
            .store(in: &set)
    }

    func onSuccessResult<Success, Failed>() -> AnyPublisher<Success, Never> where Output == Result<Success, Failed>, Failure == Never {
        self
            .compactMap { result -> Success? in
                guard case .success(let value) = result else { return nil }
                return value
            }
            .eraseToAnyPublisher()
    }

    func onFailedResult<Success, Failed>() -> AnyPublisher<Failed, Never> where Output == Result<Success, Failed>, Failure == Never {
        self
            .compactMap { result -> Failed? in
                guard case .failure(let value) = result else { return nil }
                return value
            }
            .eraseToAnyPublisher()
    }
}


extension Publishers {
    static var onCoreDataSave: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: App.shared.coreDataStack.viewContext)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
