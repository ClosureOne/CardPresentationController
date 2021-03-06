//
//  CardAnimator.swift
//  CardPresentationController
//
//  Copyright © 2018 Aleksandar Vacić, Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import UIKit

@available(iOS 10.0, *)
final class CardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	enum Direction {
		case presentation
		case dismissal
	}

	//	Init

	var direction: Direction
	var configuration: CardConfiguration

	init(direction: Direction = .presentation, configuration: CardConfiguration) {
		self.direction = direction
		self.configuration = configuration
		super.init()
	}

	//	Local configuration

	private var verticalSpacing: CGFloat { return configuration.verticalSpacing }
	private var horizontalInset: CGFloat { return configuration.horizontalInset }
	private var cornerRadius: CGFloat { return configuration.cornerRadius }
	private var backFadeAlpha: CGFloat  { return configuration.backFadeAlpha }
	private var initialTransitionFrame: CGRect? { return configuration.initialTransitionFrame }

	//	Other local stuff

	private var statusBarFrame: CGRect = UIApplication.shared.statusBarFrame
	private var initialBarStyle: UIBarStyle?

	//	MARK:- UIViewControllerAnimatedTransitioning

	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		switch direction {
		case .presentation:
			return 0.65
		case .dismissal:
			return 0.55
		}
	}

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		guard
			let fromVC = transitionContext.viewController(forKey: .from),
			let toVC = transitionContext.viewController(forKey: .to),
			let fromView = fromVC.view,
			let toView = toVC.view
		else {
			return
		}
		let containerView = transitionContext.containerView

		switch direction {
		case .presentation:
			let sourceCardPresentationController = fromVC.presentationController as? CardPresentationController

			let fromEndFrame: CGRect
			let toEndFrame: CGRect

			if let sourceCardPresentationController = sourceCardPresentationController {
				sourceCardPresentationController.fadeoutHandle()

				let fromBeginFrame = transitionContext.initialFrame(for: fromVC)
				fromEndFrame = fromBeginFrame.inset(by: UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset))

				toEndFrame = fromBeginFrame.inset(by: UIEdgeInsets(top: verticalSpacing, left: 0, bottom: 0, right: 0))

			} else {
				let fromBeginFrame = transitionContext.initialFrame(for: fromVC)
				fromEndFrame = fromBeginFrame.inset(by: UIEdgeInsets(top: statusBarFrame.height, left: horizontalInset, bottom: 0, right: horizontalInset))

				let toBaseFinalFrame = transitionContext.finalFrame(for: toVC)
				toEndFrame = toBaseFinalFrame.inset(by: UIEdgeInsets(top: statusBarFrame.height + verticalSpacing, left: 0, bottom: 0, right: 0))
			}
			let toStartFrame = offscreenFrame(inside: containerView)

			toView.clipsToBounds = true
			toView.frame = toStartFrame
			toView.layoutIfNeeded()
			containerView.addSubview(toView)

			let fromNC = fromVC as? UINavigationController
			initialBarStyle = fromNC?.navigationBar.barStyle

			let params = SpringParameters.tap
			animate({
				[weak self] in
				guard let self = self else { return }

				self.insetBackCards(of: sourceCardPresentationController)
				fromView.frame = fromEndFrame
				toView.frame = toEndFrame
				fromView.cardMaskTopCorners(using: self.cornerRadius)
				toView.cardMaskTopCorners(using: self.cornerRadius)

				if let nc = fromVC as? UINavigationController, !nc.isNavigationBarHidden {
					nc.navigationBar.barStyle = .black
				} else {
					fromView.alpha = self.backFadeAlpha
				}
			}, params: params, completion: {
				[weak self] finalAnimatingPosition in

				switch finalAnimatingPosition {
				case .end, .current:	//	Note: .current should not be possible
					self?.direction = .dismissal
					fromView.isUserInteractionEnabled = false

				case .start:
					self?.direction = .presentation
					fromView.isUserInteractionEnabled = true
				}

				transitionContext.completeTransition(true)
			})

		case .dismissal:
			let targetCardPresentationController = toVC.presentationController as? CardPresentationController
			let isTargetAlreadyCard = (targetCardPresentationController != nil)

			let toBeginFrame = toView.frame
			let toEndFrame: CGRect

			if let targetCardPresentationController = targetCardPresentationController {
				targetCardPresentationController.fadeinHandle()
				toEndFrame = toBeginFrame.inset(by: UIEdgeInsets(top: 0, left: -horizontalInset, bottom: 0, right: -horizontalInset))

			} else {
				toEndFrame = transitionContext.finalFrame(for: toVC)
			}

			let fromEndFrame = offscreenFrame(inside: containerView)

			let params = SpringParameters.momentum
			animate({
				[weak self] in
				guard let self = self else { return }

				fromView.cardUnmask()
				if !isTargetAlreadyCard {
					toView.cardUnmask()
				}
				self.outsetBackCards(of: targetCardPresentationController)

				fromView.frame = fromEndFrame
				toView.frame = toEndFrame
				toView.alpha = 1
				fromView.alpha = 1

				if
					let nc = toVC as? UINavigationController,
					let barStyle = self.initialBarStyle
				{
					nc.navigationBar.barStyle = barStyle
				}
			}, params: params, completion: {
				[weak self] finalAnimatingPosition in

				switch finalAnimatingPosition {
				case .end, .current:	//	Note: .current should not be possible
					self?.direction = .presentation
					toView.isUserInteractionEnabled = true
					fromView.removeFromSuperview()

				case .start:
					self?.direction = .dismissal
					toView.isUserInteractionEnabled = false
				}

				transitionContext.completeTransition(true)
			})
		}
	}
}


private extension CardAnimator {
	private func insetBackCards(of pc: CardPresentationController?) {
		guard
			let pc = pc,
			let pcView = pc.presentingViewController.view
		else { return }

		let frame = pcView.frame
		pcView.frame = frame.inset(by: UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset))
		pcView.alpha *= backFadeAlpha

		insetBackCards(of: pc.presentingViewController.presentationController as? CardPresentationController)
	}

	private func outsetBackCards(of pc: CardPresentationController?) {
		guard
			let pc = pc,
			let pcView = pc.presentingViewController.view
		else { return }

		let frame = pcView.frame
		pcView.frame = frame.inset(by: UIEdgeInsets(top: 0, left: -horizontalInset, bottom: 0, right: -horizontalInset))
		pcView.alpha /= backFadeAlpha

		outsetBackCards(of: pc.presentingViewController.presentationController as? CardPresentationController)
	}

	func offscreenFrame(inside containerView: UIView) -> CGRect {
		if let initialTransitionFrame = initialTransitionFrame {
			return initialTransitionFrame
		} else {
			var f = containerView.frame
			f.origin.y = f.height
			return f
		}
	}

	struct SpringParameters {
		let damping: CGFloat
		let response: CGFloat

		//	From amazing session 803 at WWDC 2018: https://developer.apple.com/videos/play/wwdc2018-803/?time=2238
		//	> Because the tap doesn't have any momentum in the direction of the presentation of Now Playing,
		//	> we use 100% damping to make sure it doesn't overshoot.
		//
		static let tap = SpringParameters(damping: 1, response: 0.44)

		//	> But, if you swipe to dismiss Now Playing,
		//	> there is momentum in the direction of the dismissal,
		//	> and so we use 80% damping to have a little bit of bounce and squish,
		//	> making the gesture a lot more satisfying.
		//
		//	(note that they use momentum even when tapping to dismiss)
		static let momentum = SpringParameters(damping: 0.8, response: 0.44)
	}

	func animate(_ animation: @escaping () -> Void, params: SpringParameters, completion: @escaping (UIViewAnimatingPosition) -> Void) {
		//	entire spring animation should not last more than transitionDuration
		let damping = params.damping
		let response = params.response

		let timingParameters = UISpringTimingParameters(damping: damping, response: response)
		let pa = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
		pa.addAnimations(animation)
		pa.addCompletion(completion)
/*
		//	simple way to measure total time of the transition
		//	add about 0.02 for good measure and use that value for transitionDuration

		let ts = CACurrentMediaTime()
		pa.addCompletion {
			_ in
			let te = CACurrentMediaTime()
			print(te - ts)
		}
*/
		pa.startAnimation()
	}
}



fileprivate extension UIViewControllerContextTransitioning {
	var fromContentController: UIViewController? {
		guard let topVC = viewController(forKey: .from) else { return nil }
		return recognize(topVC)
	}

	var toContentController: UIViewController? {
		guard let topVC = viewController(forKey: .to) else { return nil }
		return recognize(topVC)
	}

	func recognize(_ vc: UIViewController) -> UIViewController? {
		switch vc {
		case let nc as UINavigationController:
			return nc.topViewController ?? nc

		case let tbc as UITabBarController:
			guard let vc = tbc.selectedViewController else { return tbc }
			return recognize(vc)

		default:
			return vc
		}
	}
}


private extension UISpringTimingParameters {
	/// A design-friendly way to create a spring timing curve.
	///	See: https://medium.com/@nathangitter/building-fluid-interfaces-ios-swift-9732bb934bf5
	///
	/// - Parameters:
	///   - damping: The 'bounciness' of the animation. Value must be between 0 and 1.
	///   - response: The 'speed' of the animation.
	///   - initialVelocity: The vector describing the starting motion of the property. Optional, default is `.zero`.
	convenience init(damping: CGFloat, response: CGFloat, initialVelocity: CGVector = .zero) {
		let stiffness = pow(2 * .pi / response, 2)
		let damp = 4 * .pi * damping / response
		self.init(mass: 1, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
	}

}
