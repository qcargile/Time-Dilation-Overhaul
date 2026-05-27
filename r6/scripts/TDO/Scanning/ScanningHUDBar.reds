module TDO.Scanning

import Codeware.UI.VirtualResolutionWatcher

public class TDO_ScanningBar {

  private let m_created: Bool;
  private let m_fullScreenSlot: ref<inkCanvas>;
  private let m_widgetSlot: ref<inkCanvas>;
  private let m_bg: ref<inkRectangle>;
  private let m_fill: ref<inkRectangle>;
  private let m_resWatcher: ref<VirtualResolutionWatcher>;

  public func EnsureCreated() -> Void {
    if this.m_created {
      return;
    }
    let inkSystem: ref<inkSystem> = GameInstance.GetInkSystem();
    if !IsDefined(inkSystem) {
      return;
    }
    let layer = inkSystem.GetLayer(n"inkHUDLayer");
    if !IsDefined(layer) {
      return;
    }
    let inkHUD: ref<inkCompoundWidget> = layer.GetVirtualWindow();
    if !IsDefined(inkHUD) {
      return;
    }
    let root: ref<inkCompoundWidget> = inkHUD.GetWidgetByPathName(n"Root") as inkCompoundWidget;
    if !IsDefined(root) {
      return;
    }
    let existing: ref<inkCompoundWidget> = inkHUD.GetWidgetByPathName(n"Root/TDOScanBarFullScreenSlot") as inkCompoundWidget;
    if IsDefined(existing) {
      this.m_fullScreenSlot = existing as inkCanvas;
      this.m_widgetSlot = inkHUD.GetWidgetByPathName(n"Root/TDOScanBarFullScreenSlot/TDOScanBarSlot") as inkCanvas;
      this.m_bg = inkHUD.GetWidgetByPathName(n"Root/TDOScanBarFullScreenSlot/TDOScanBarSlot/bg") as inkRectangle;
      this.m_fill = inkHUD.GetWidgetByPathName(n"Root/TDOScanBarFullScreenSlot/TDOScanBarSlot/fill") as inkRectangle;
      this.m_created = true;
      return;
    }

    let full: ref<inkCanvas> = new inkCanvas();
    full.SetName(n"TDOScanBarFullScreenSlot");
    full.SetSize(Vector2(3840.0, 2160.0));
    full.SetRenderTransformPivot(Vector2(0.0, 0.0));
    full.Reparent(root);
    this.m_fullScreenSlot = full;

    let slot: ref<inkCanvas> = new inkCanvas();
    slot.SetName(n"TDOScanBarSlot");
    slot.SetFitToContent(true);
    slot.SetTranslation(TDOConfig.ScanningBarPosX(), TDOConfig.ScanningBarPosY());
    slot.Reparent(full);
    this.m_widgetSlot = slot;

    let w: Float = TDOConfig.ScanningBarWidth();
    let h: Float = TDOConfig.ScanningBarHeight();

    let bg: ref<inkRectangle> = new inkRectangle();
    bg.SetName(n"bg");
    bg.SetHAlign(inkEHorizontalAlign.Left);
    bg.SetVAlign(inkEVerticalAlign.Center);
    bg.SetSize(Vector2(w, h));
    bg.SetOpacity(0.35);
    bg.SetTintColor(HDRColor(0.05, 0.07, 0.09, 1.0));
    bg.Reparent(slot);
    this.m_bg = bg;

    let fill: ref<inkRectangle> = new inkRectangle();
    fill.SetName(n"fill");
    fill.SetHAlign(inkEHorizontalAlign.Left);
    fill.SetVAlign(inkEVerticalAlign.Center);
    fill.SetSize(Vector2(w, h));
    fill.SetTintColor(HDRColor(0.16, 0.85, 0.94, 1.0));
    fill.Reparent(slot);
    this.m_fill = fill;

    this.m_resWatcher = new VirtualResolutionWatcher();
    this.m_resWatcher.Initialize(GetGameInstance());
    this.m_resWatcher.ScaleWidget(full);

    this.m_created = true;
  }

  public func Update(charge: Float, scannerOpen: Bool) -> Void {
    if !this.m_created {
      return;
    }
    if !IsDefined(this.m_widgetSlot) || !IsDefined(this.m_bg) || !IsDefined(this.m_fill) {
      return;
    }
    let w: Float = TDOConfig.ScanningBarWidth();
    let h: Float = TDOConfig.ScanningBarHeight();
    let c: Float = ClampF(charge, 0.0, 1.0);
    this.m_widgetSlot.SetTranslation(TDOConfig.ScanningBarPosX(), TDOConfig.ScanningBarPosY());
    this.m_bg.SetSize(Vector2(w, h));
    this.m_fill.SetSize(Vector2(w * c, h));
    this.m_widgetSlot.SetVisible(scannerOpen);
  }
}
