//
//  BothObservable.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/12/10.
//

protocol Observer {
     func observe<O>(for observable: BothObservable<O>, with: @escaping (O) -> Void)
}

final class BothObservable<ObservedType> {

    typealias Observer = (_ observable: ObservedType) -> ()

    var value: ObservedType? {
        didSet {
            guard value.debugDescription.contains(oldValue.debugDescription) else {
                if let value = value { notifyObservers(value) }
                return
            }
        }
    }

    private var observers: [Observer] = []

    func bind(observer: @escaping Observer) { self.observers.append(observer) }

    private func notifyObservers(_ value: ObservedType) { self.observers.forEach { observer in observer(value) }

    }
}
