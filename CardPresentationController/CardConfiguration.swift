//
//  CardConfiguration.swift
//  CardPresentationController
//
//  Copyright © 2018 Aleksandar Vacić, Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import UIKit

///	Simple package for various values defining transition's look & feel.
///
///	Supply it as optional parameter to `presentCard(...)`.
public struct CardConfiguration {
	///	Vertical inset from the top or already shown card.
	var verticalSpacing: CGFloat = 16

	///	Leading and trailing inset for the existing (presenting) view when it's being pushed further back.
	var horizontalInset: CGFloat = 16

	///	Cards have rounded corners, right?
	var cornerRadius: CGFloat = 12

	///	The starting frame for the presented card.
	var initialTransitionFrame: CGRect?

	///	How much to fade the back card.
	///
	///	Ignored if back card is UINavigationController
	var backFadeAlpha: CGFloat = 0.8

	///	Default initializer, with most suitable values
	init() {}
}

extension CardConfiguration {
	///	Very convenient initializer; supply only those params which are different from default ones.
	public init(verticalSpacing: CGFloat? = nil,
		 horizontalInset: CGFloat? = nil,
		 cornerRadius: CGFloat? = nil,
		 backFadeAlpha: CGFloat? = nil,
		 initialTransitionFrame: CGRect? = nil)
	{
		if let verticalSpacing = verticalSpacing {
			self.verticalSpacing = verticalSpacing
		}

		if let horizontalInset = horizontalInset {
			self.horizontalInset = horizontalInset
		}

		if let cornerRadius = cornerRadius {
			self.cornerRadius = cornerRadius
		}

		if let backFadeAlpha = backFadeAlpha {
			self.backFadeAlpha = backFadeAlpha
		}

		if let initialTransitionFrame = initialTransitionFrame {
			self.initialTransitionFrame = initialTransitionFrame
		}
	}
}
