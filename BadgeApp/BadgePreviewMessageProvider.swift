//
//  BadgePreviewMessageProvider.swift
//  BadgeApp
//
//  Created by David Vilches on 15/05/2026.
//

import Foundation

final class BadgePreviewMessageProvider {
    func previewMessage(for status: DroppedItemBadgeStatus) -> String {
        switch status {
        case .none:
            return "Coloca el badge\ndonde desees.\nArrastralo sobre\nla previsualizacion."
        case .badgeAppEditable:
            return "Badge aplicado\ndetectado.\nPuedes moverlo o\ncambiarlo aqui."
        case .badgeAppAppliedNotEditable:
            return "Badge aplicado\ndetectado.\nSe previsualiza uno\nnuevo encima."
        case .externalCustomIcon:
            return "Icono personalizado\ndetectado.\nLa preview anade\nun badge encima."
        }
    }

    func loadMessage(for status: DroppedItemBadgeStatus) -> String {
        switch status {
        case .none:
            return "Elemento cargado.\nPulsa Previsualizar\npara anadir un badge."
        case .badgeAppEditable:
            return "Badge de BadgeApp\ndetectado.\nSe muestra el estado\nreal del elemento."
        case .badgeAppAppliedNotEditable:
            return "Badge aplicado\ndetectado.\nNo se puede separar\ndel icono actual."
        case .externalCustomIcon:
            return "Icono personalizado\ndetectado.\nSe usa como base\nde trabajo."
        }
    }
}
