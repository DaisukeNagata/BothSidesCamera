//
//  BothObserveViewModel.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/12/10.
//

import Foundation

class BothObserveViewModel: Observer {

    var model : BothObservable<IsRunningModel>?
    var sameRatioModel : BothObservable<SameRatioModel>?

    init() {
        model = BothObservable()
        sameRatioModel = BothObservable()
    }

   func valueSet(_ model: IsRunningModel) { self.model?.value = model }

   func sameValueSet(_ sameRatioModel: SameRatioModel) { self.sameRatioModel?.value = sameRatioModel }

   func observe<O>(for observable: BothObservable<O>, with: @escaping (O) -> Void) { observable.bind(observer: with) }
}
