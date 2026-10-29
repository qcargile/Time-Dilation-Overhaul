module TDO.Sandy

import Codeware.UI.ScreenHelper

public class TDO_ShrikeHUD {
  private let m_root: wref<inkCompoundWidget>;
  private let m_canvas: ref<inkCanvas>;
  private let m_countText: ref<inkText>;
  private let m_statusText: ref<inkText>;
  private let m_bar: ref<inkCanvas>;
  private let m_fill: ref<inkRectangle>;
  private let m_markCount: Int32;
  private let m_maxMarks: Int32;
  private let m_status: CName;
  private let m_seconds: Int32;
  private let m_progress: Float;
  private let m_visible: Bool;
  private let m_scale: Float;
  private let m_nextResolutionCheck: Float;

  public func Update(markCount: Int32, maxMarks: Int32, status: CName, progress: Float, seconds: Int32, visible: Bool) -> Void {
    if !visible || TDOConfig.UIHideAll() {
      if this.m_visible && IsDefined(this.m_canvas) {
        this.m_canvas.SetVisible(false);
        this.m_visible = false;
      }
      return;
    }
    if !this.EnsureCreated() {
      return;
    }
    this.RefreshScale();
    if markCount != this.m_markCount || maxMarks != this.m_maxMarks {
      this.m_countText.SetText(GetLocalizedTextByKey(n"UI-TDO-ShrikeMarks") + " " + IntToString(markCount) + "/" + IntToString(maxMarks));
      this.m_markCount = markCount;
      this.m_maxMarks = maxMarks;
    }
    if NotEquals(status, this.m_status) || seconds != this.m_seconds {
      if NotEquals(status, n"") {
        let text: String = GetLocalizedTextByKey(status);
        if seconds > 0 {
          text += " " + IntToString(seconds) + GetLocalizedTextByKey(n"UI-TDO-ShrikeSeconds");
        }
        this.m_statusText.SetText(text);
      }
      this.m_statusText.SetVisible(NotEquals(status, n""));
      this.m_status = status;
      this.m_seconds = seconds;
    }
    let fill: Float = progress < 0.0 ? -1.0 : ClampF(progress, 0.0, 1.0);
    if fill != this.m_progress {
      this.m_bar.SetVisible(fill >= 0.0);
      if fill >= 0.0 {
        this.m_fill.SetSize(Vector2(240.0 * fill, 4.0));
      }
      this.m_progress = fill;
    }
    if !this.m_visible {
      this.m_canvas.SetVisible(true);
      this.m_visible = true;
    }
  }

  public func Remove() -> Void {
    if IsDefined(this.m_root) && IsDefined(this.m_canvas) {
      this.m_root.RemoveChild(this.m_canvas);
    }
    this.m_fill = null;
    this.m_bar = null;
    this.m_statusText = null;
    this.m_countText = null;
    this.m_canvas = null;
    this.m_root = null;
    this.m_markCount = -1;
    this.m_maxMarks = -1;
    this.m_status = n"";
    this.m_seconds = -1;
    this.m_progress = -1.0;
    this.m_visible = false;
    this.m_scale = 0.0;
    this.m_nextResolutionCheck = 0.0;
  }

  private func EnsureCreated() -> Bool {
    let inkSystem: ref<inkSystem> = GameInstance.GetInkSystem();
    if !IsDefined(inkSystem) {
      this.Remove();
      return false;
    }
    let layer = inkSystem.GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      this.Remove();
      return false;
    }
    let window: ref<inkCompoundWidget> = layer.GetVirtualWindow();
    if !IsDefined(window) {
      this.Remove();
      return false;
    }
    let root: ref<inkCompoundWidget> = window.GetWidgetByPathName(n"Root") as inkCompoundWidget;
    if !IsDefined(root) {
      this.Remove();
      return false;
    }
    let existing: ref<inkWidget> = root.GetWidgetByPathName(n"TDOShrikeHUD");
    if Equals(this.m_root, root) && IsDefined(this.m_canvas) && Equals(existing, this.m_canvas) {
      return true;
    }
    this.Remove();
    existing = root.GetWidgetByPathName(n"TDOShrikeHUD");
    while IsDefined(existing) {
      root.RemoveChild(existing);
      existing = root.GetWidgetByPathName(n"TDOShrikeHUD");
    }
    this.m_root = root;
    let canvas: ref<inkCanvas> = new inkCanvas();
    canvas.SetName(n"TDOShrikeHUD");
    canvas.SetSize(Vector2(3840.0, 2160.0));
    canvas.SetAnchor(inkEAnchor.Centered);
    canvas.SetAnchorPoint(Vector2(0.5, 0.5));
    canvas.SetRenderTransformPivot(Vector2(0.5, 0.5));
    canvas.SetVisible(false);
    canvas.Reparent(root);
    this.m_canvas = canvas;

    let slot: ref<inkCanvas> = new inkCanvas();
    slot.SetName(n"shrike");
    slot.SetSize(Vector2(480.0, 110.0));
    slot.SetTranslation(2040.0, 1180.0);
    slot.Reparent(canvas);

    let count: ref<inkText> = new inkText();
    count.SetName(n"count");
    count.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    count.SetFontStyle(n"Semi-Bold");
    count.SetFontSize(32);
    count.SetSize(Vector2(480.0, 42.0));
    count.SetTintColor(HDRColor(0.16, 0.85, 0.94, 1.0));
    count.Reparent(slot);
    this.m_countText = count;

    let status: ref<inkText> = new inkText();
    status.SetName(n"status");
    status.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
    status.SetFontStyle(n"Regular");
    status.SetFontSize(28);
    status.SetSize(Vector2(480.0, 42.0));
    status.SetTranslation(0.0, 38.0);
    status.SetTintColor(HDRColor(0.16, 0.85, 0.94, 1.0));
    status.SetVisible(false);
    status.Reparent(slot);
    this.m_statusText = status;

    let bar: ref<inkCanvas> = new inkCanvas();
    bar.SetName(n"progress");
    bar.SetSize(Vector2(240.0, 4.0));
    bar.SetTranslation(0.0, 82.0);
    bar.SetVisible(false);
    bar.Reparent(slot);
    this.m_bar = bar;

    let background: ref<inkRectangle> = new inkRectangle();
    background.SetName(n"background");
    background.SetSize(Vector2(240.0, 4.0));
    background.SetTintColor(HDRColor(0.05, 0.07, 0.09, 1.0));
    background.SetOpacity(0.65);
    background.Reparent(bar);

    let fill: ref<inkRectangle> = new inkRectangle();
    fill.SetName(n"fill");
    fill.SetSize(Vector2(0.0, 4.0));
    fill.SetTintColor(HDRColor(0.16, 0.85, 0.94, 1.0));
    fill.Reparent(bar);
    this.m_fill = fill;
    return true;
  }

  private func RefreshScale() -> Void {
    let now: Float = EngineTime.ToFloat(GameInstance.GetEngineTime(GetGameInstance()));
    if now < this.m_nextResolutionCheck {
      return;
    }
    this.m_nextResolutionCheck = now + 1.0;
    let size: Vector2 = ScreenHelper.GetScreenSize(GetGameInstance());
    if size.X > 0.0 && size.Y > 0.0 {
      let scale: Float = MinF(size.X / 3840.0, size.Y / 2160.0);
      if scale != this.m_scale {
        this.m_canvas.SetScale(Vector2(scale, scale));
        this.m_scale = scale;
      }
    }
  }
}
