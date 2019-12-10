//
//  BothObserveViewModel.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/12/10.
//

import Foundation

class BothObserveViewModel: Observer {

    var model : BothObservable<BothObservarModel>?

    init() {
        model = BothObservable()
    }

    func valueSet(_ model: BothObservarModel) { self.model?.value = model }

    func observe<O>(for observable: BothObservable<O>, with: @escaping (O) -> Void) { observable.bind(observer: with) }
}
