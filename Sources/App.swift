import SwiftUI
import UIKit

// MARK: - 触感
func kxTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let g = UIImpactFeedbackGenerator(style: style)
    g.prepare()
    g.impactOccurred()
}

// MARK: - 状态
enum IslandMode: String, CaseIterable, Identifiable {
    case idle = "待机"
    case music = "音乐"
    case timer = "计时"
    case call = "来电"
    var id: String { rawValue }
}

final class IslandModel: ObservableObject {
    @Published var mode: IslandMode = .music
    @Published var expanded = false
    @Published var playing = true
    @Published var progress: Double = 0.28
    @Published var remaining: Int = 138
    @Published var answering = false

    func cycleShot() {
        // 小动画：切歌时进度回零
        progress = 0.02
    }
}

// MARK: - 音柱
struct Bars: View {
    var count: Int = 4
    var active: Bool = true
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(Color(red: 0.36, green: 0.98, blue: 0.72))
                    .frame(width: 2.5, height: 12)
                    .scaleEffect(y: active ? (phase > 0.5 ? 1.0 : 0.35) : 0.4,
                                 anchor: .center)
                    .animation(
                        active ? .easeInOut(duration: 0.42 + Double(i) * 0.09).repeatForever(autoreverses: true) : .default,
                        value: phase
                    )
            }
        }
        .frame(height: 14)
        .onAppear { phase = 1 }
    }
}

// MARK: - 灵动岛
struct IslandView: View {
    @ObservedObject var m: IslandModel
    @State private var pressPulse = false

    private var screenW: CGFloat { UIScreen.main.bounds.width }
    private var collapsedW: CGFloat { m.mode == .idle ? 116 : 134 }
    private var w: CGFloat { m.expanded ? screenW - 32 : collapsedW }
    private var h: CGFloat { m.expanded ? (m.mode == .call ? 168 : 158) : 38 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: h / 2, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: h / 2, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.45), radius: m.expanded ? 24 : 10, x: 0, y: m.expanded ? 12 : 5)

            content
                .padding(.horizontal, m.expanded ? 16 : 10)
        }
        .frame(width: w, height: h)
        .scaleEffect(pressPulse ? 0.965 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            kxTap()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                m.expanded.toggle()
            }
        }
        .onLongPressGesture(minimumDuration: 0.01) {
            // 长按只做视觉反馈
        } onPressingChanged: { down in
            withAnimation(.easeOut(duration: 0.12)) { pressPulse = down }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.74), value: m.expanded)
        .animation(.spring(response: 0.42, dampingFraction: 0.74), value: m.mode)
    }

    @ViewBuilder
    private var content: some View {
        if !m.expanded {
            collapsed
        } else {
            switch m.mode {
            case .music: musicBig
            case .timer: timerBig
            case .call: callBig
            case .idle: idleBig
            }
        }
    }

    // 收起态
    private var collapsed: some View {
        HStack(spacing: 8) {
            if m.mode == .music {
                Bars(count: 4, active: m.playing)
                Spacer(minLength: 0)
                Circle()
                    .fill(Color(red: 0.36, green: 0.98, blue: 0.72).opacity(0.18))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.36, green: 0.98, blue: 0.72))
                    )
            } else if m.mode == .timer {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.orange)
                Spacer(minLength: 0)
                Text(mmss(m.remaining))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .monospacedDigit()
            } else if m.mode == .call {
                Circle().fill(Color(red: 0.24, green: 0.78, blue: 0.45)).frame(width: 20, height: 20)
                    .overlay(Image(systemName: "phone.fill").font(.system(size: 9)).foregroundColor(.white))
                Spacer(minLength: 0)
                Text("来电").font(.system(size: 11, weight: .semibold)).foregroundColor(.white)
            } else {
                Circle().fill(Color(red: 0.15, green: 0.55, blue: 0.95)).frame(width: 8, height: 8)
                Spacer(minLength: 0)
                Circle().fill(Color.white.opacity(0.25)).frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // 展开：音乐
    private var musicBig: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.42, blue: 0.98),
                                             Color(red: 0.62, green: 0.24, blue: 0.9)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 58, height: 58)
                .overlay(Image(systemName: "music.note").font(.system(size: 22, weight: .semibold)).foregroundColor(.white))

            VStack(alignment: .leading, spacing: 4) {
                Text("晴天").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text("周杰伦").font(.system(size: 11)).foregroundColor(Color.white.opacity(0.55))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.16)).frame(height: 3)
                        Capsule()
                            .fill(Color(red: 0.36, green: 0.98, blue: 0.72))
                            .frame(width: max(3, geo.size.width * CGFloat(min(max(m.progress, 0), 1))), height: 3)
                    }
                }
                .frame(height: 3)
                .padding(.top, 2)
            }

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Button(action: { kxTap(.light); m.cycleShot() }) {
                        Image(systemName: "backward.fill").font(.system(size: 12)).foregroundColor(.white.opacity(0.75))
                    }
                    Button(action: { kxTap(); m.playing.toggle() }) {
                        Image(systemName: m.playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    }
                    Button(action: { kxTap(.light); m.cycleShot() }) {
                        Image(systemName: "forward.fill").font(.system(size: 12)).foregroundColor(.white.opacity(0.75))
                    }
                }
                Bars(count: 5, active: m.playing)
            }
        }
    }

    // 展开：计时
    private var timerBig: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.14), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: CGFloat(1 - Double(m.remaining) / 180.0))
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(mmss(m.remaining))
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(.white).monospacedDigit()
                Text("倒计时 · 3 分钟").font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
            Button(action: { kxTap(); m.remaining = 180 }) {
                Text("重置")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().fill(Color.orange.opacity(0.16)))
            }
        }
    }

    // 展开：来电
    private var callBig: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.35, green: 0.4, blue: 0.52),
                                                 Color(red: 0.2, green: 0.24, blue: 0.34)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 42, height: 42)
                    .overlay(Text("李").font(.system(size: 16, weight: .semibold)).foregroundColor(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text("李赛").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text(m.answering ? "通话中 00:12" : "iPhone 来电").font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 14) {
                Button(action: { kxTap(); m.mode = .idle; m.answering = false; m.expanded = false }) {
                    label(icon: "phone.down.fill", text: "拒绝", tint: Color(red: 0.92, green: 0.28, blue: 0.32))
                }
                Button(action: { kxTap(); m.answering.toggle() }) {
                    label(icon: "phone.fill", text: m.answering ? "挂断" : "接听",
                          tint: Color(red: 0.24, green: 0.78, blue: 0.45))
                }
            }
        }
    }

    private func label(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold))
            Text(text).font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Capsule().fill(tint.opacity(0.28)))
    }

    private var idleBig: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles").font(.system(size: 16)).foregroundColor(Color(red: 0.36, green: 0.98, blue: 0.72))
            VStack(alignment: .leading, spacing: 2) {
                Text("灵动岛已就绪").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text("在下方选择一种状态").font(.system(size: 11)).foregroundColor(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
        }
    }
}

func mmss(_ s: Int) -> String {
    let v = max(s, 0)
    return String(format: "%02d:%02d", v / 60, v % 60)
}

// MARK: - 主界面
struct RootView: View {
    @StateObject private var m = IslandModel()
    @State private var lockScreen = false
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            background

            if lockScreen {
                lockPreview
            } else {
                normal
            }
        }
        .ignoresSafeArea()
        .onReceive(tick) { _ in
            if m.playing && m.mode == .music {
                m.progress += 0.012
                if m.progress > 1 { m.progress = 0.02 }
            }
            if m.mode == .timer && m.remaining > 0 { m.remaining -= 1 }
        }
    }

    private var background: some View {
        LinearGradient(colors: [Color(red: 0.03, green: 0.04, blue: 0.06),
                                Color(red: 0.07, green: 0.08, blue: 0.12)],
                       startPoint: .top, endPoint: .bottom)
    }

    private var normal: some View {
        VStack(spacing: 0) {
            HStack {
                Text("灵动岛").font(.system(size: 13, weight: .medium)).foregroundColor(.white.opacity(0.45))
                Spacer()
                Button(action: { kxTap(); withAnimation(.easeInOut(duration: 0.25)) { lockScreen = true } }) {
                    Text("锁屏预览")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.36, green: 0.98, blue: 0.72))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 54)

            IslandView(m: m)
                .padding(.top, 10)

            Spacer(minLength: 0)

            VStack(spacing: 18) {
                Text("点上面那块黑色区域看展开动画")
                    .font(.system(size: 12)).foregroundColor(.white.opacity(0.35))

                HStack(spacing: 10) {
                    ForEach(IslandMode.allCases) { mode in
                        Button(action: {
                            kxTap(.light)
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.74)) {
                                m.mode = mode
                                m.expanded = false
                            }
                            m.answering = false
                        }) {
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(m.mode == mode ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(m.mode == mode ? Color.white.opacity(0.13) : Color.white.opacity(0.05))
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)

                Text("iPhone 12 Pro Max · 模拟灵动岛")
                    .font(.system(size: 10)).foregroundColor(.white.opacity(0.22))
                    .padding(.bottom, 20)
            }
        }
    }

    // 模仿锁屏：岛在正中间偏上
    private var lockPreview: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.10, green: 0.13, blue: 0.24),
                                    Color(red: 0.32, green: 0.14, blue: 0.22),
                                    Color(red: 0.05, green: 0.06, blue: 0.10)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)

            VStack(spacing: 0) {
                IslandView(m: m)
                    .padding(.top, 10)

                VStack(spacing: 6) {
                    Text("11月20日 星期五").font(.system(size: 13)).foregroundColor(.white.opacity(0.55))
                    Text("09:41").font(.system(size: 62, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 28)

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    HStack {
                        Image(systemName: "flashlight.off.fill").font(.system(size: 18))
                        Spacer()
                        Image(systemName: "camera.fill").font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 42)

                    Capsule().fill(Color.white.opacity(0.35)).frame(width: 130, height: 5)
                        .padding(.bottom, 12)
                }
            }

            VStack {
                Spacer()
                Button(action: { kxTap(); withAnimation(.easeInOut(duration: 0.25)) { lockScreen = false } }) {
                    Text("退出预览")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                }
                .padding(.bottom, 66)
            }
        }
    }
}

@main
struct LingdaoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
