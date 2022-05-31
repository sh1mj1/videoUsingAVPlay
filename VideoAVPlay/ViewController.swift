//
//  ViewController.swift
//  VideoAVPlay
//
//  Created by 심지훈 on 2022/05/31.
//


import UIKit
import AVFoundation
import SnapKit

class ViewController: UIViewController {
    
    //상단 제목
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오디오 재생 예제"
        label.textAlignment = .center
        // whether the view’s autoresizing mask is translated into Auto Layout constraints.
        // AutoSizingMask: superView의 bounds가 변경될 때 receiver(subView)의 size를 조정하는 방법을 결정하는 bit mask
        self.view.addSubview(label)
        return label
    }()
    
    // 경과 시간
    private lazy var elapsedTimeLabel: UILabel = {
        let label = UILabel()
        self.view.addSubview(label)
        return label
    }()
    
    // 음원 총 시간
    private lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        self.view.addSubview(label)
        return label
    }()
    
    // playSlider
    private lazy var playSlider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(didChangeSlide), for: .valueChanged)
        self.view.addSubview(slider)
        return slider
    }()
    
    // 재생 & 일시정지
    private lazy var toggleButton: UIButton = {
        let button = UIButton()
        button.setTitle("재생", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(.blue, for: .highlighted)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.view.addSubview(button)
        return button
    }()
    
    // player
    var player: AVPlayer = {
        guard let url = Bundle.main.url(forResource: "dummyVideo", withExtension: "mp4") else {fatalError()}
        let player = AVPlayer()
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem) // AVPlayer는 한번에 하나씩만 다룰 수 있음
        return player
    }()
    
    var buttonTitle: String? {
        didSet { self.toggleButton.setTitle(self.buttonTitle, for: .normal) }
    }
    
    // Float64 타입 값을 String으로 변경해서 UILabel의 text에 입력
    // (elpasedTimeSecondsFloat, totalTimeSecondsFloat 변수의 didSet에서 수행)
    var elapsedTimeSecondsFloat: Float64 = 0 {
        didSet {
            guard self.elapsedTimeSecondsFloat != oldValue else { return }
            let elapsedSecondsInt = Int(self.elapsedTimeSecondsFloat)
            let elapsedTimeText = String(format: "%02d:%02d", elapsedSecondsInt.miniuteDigitInt, elapsedSecondsInt.secondsDigitInt)
            self.elapsedTimeLabel.text = elapsedTimeText
            self.progressValue = self.elapsedTimeSecondsFloat / self.totalTimeSecondsFloat
        }
    }
    
    var totalTimeSecondsFloat: Float64 = 0 {
        didSet {
            guard self.totalTimeSecondsFloat != oldValue else { return }
            let totalSecondsInt = Int(self.totalTimeSecondsFloat)
            let totalTimeText = String(format: "%02d:%02d", totalSecondsInt.miniuteDigitInt, totalSecondsInt.secondsDigitInt)
            self.totalTimeLabel.text = totalTimeText
        }
    }
    
    var progressValue: Float64? {
        didSet { self.playSlider.value = Float(self.elapsedTimeSecondsFloat / self.totalTimeSecondsFloat) }
    }
    
    // MARK : - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View들 Constraint 주기
        self.titleLabel.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide).inset(16)
            $0.centerX.equalToSuperview()
        }
        self.playSlider.snp.makeConstraints {
            $0.top.equalTo(self.view.safeAreaLayoutGuide).inset(56)
            $0.left.right.equalToSuperview().inset(16)
        }
        self.elapsedTimeLabel.snp.makeConstraints {
            $0.top.equalTo(self.playSlider.snp.bottom).offset(8)
            $0.left.equalTo(self.playSlider)
        }
        self.totalTimeLabel.snp.makeConstraints {
            $0.top.equalTo(self.playSlider.snp.bottom).offset(8)
            $0.right.equalTo(self.playSlider)
        }
        self.toggleButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        // Observer 등록
        self.addPeriodicTimeObserver()
    }
    
    // 현재까지 재생된 시간 정보를 휙득(Observing)
    private func addPeriodicTimeObserver() {
        
        // 1초마다 데이터를 받는다는 의미
        let interval = CMTimeMakeWithSeconds(1, preferredTimescale: Int32(NSEC_PER_SEC))
        
        self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] elapsedTime in
            let elapsedTimeSecondsFloat = CMTimeGetSeconds(elapsedTime)
            let totalTimeSecondsFloat = CMTimeGetSeconds(self?.player.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
            guard
                !elapsedTimeSecondsFloat.isNaN,
                !elapsedTimeSecondsFloat.isInfinite,
                !totalTimeSecondsFloat.isNaN,
                !totalTimeSecondsFloat.isInfinite
            else { return }
            self?.elapsedTimeSecondsFloat = elapsedTimeSecondsFloat
            self?.totalTimeSecondsFloat = totalTimeSecondsFloat
        }
    }
    
    // MARK : - Actions
    @objc private func didTapButton() {
        switch self.player.timeControlStatus {
        case .paused:
            self.player.play()
            self.buttonTitle = "일시정지"
            
        case .playing:
            self.player.pause()
            self.buttonTitle = "재생"
        default:
            break
        }
    }
    
    @objc private func didChangeSlide() {
        self.elapsedTimeSecondsFloat = Float64(self.playSlider.value) * self.totalTimeSecondsFloat
        // 1초마다 데이터를 받는다.
        self.player.seek(to: CMTimeMakeWithSeconds(self.elapsedTimeSecondsFloat, preferredTimescale: Int32(NSEC_PER_SEC)))
    }
}

extension Int {
    var secondsDigitInt: Int {
        self % 60
    }
    var miniuteDigitInt: Int {
        self / 60
    }
}
