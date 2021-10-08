//
//  ReplayPanel.swift
//  TrailerPlayer
//
//  Created by Abe Wang on 2021/10/8.
//

import UIKit

protocol ReplayPanelDelegate: AnyObject {
    func replayPanel(_ panel: ReplayPanel, didTapReplayButton: UIButton)
}

class ReplayPanel: UIView {

    weak var delegate: ReplayPanelDelegate?
    
    @AutoLayout
    var replayButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = .white
        button.setImage(UIImage(named: "replay")?.withRenderingMode(.alwaysTemplate), for: .normal)
        return button
    }()

    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ReplayPanel {
    
    func setup() {
        backgroundColor = .black.withAlphaComponent(0.5)
        
        addSubview(replayButton)
        replayButton.addTarget(self, action: #selector(didTapReplay), for: .touchUpInside)
        replayButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        replayButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        replayButton.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        replayButton.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
    }
    
    @objc func didTapReplay() {
        delegate?.replayPanel(self, didTapReplayButton: replayButton)
    }
}
