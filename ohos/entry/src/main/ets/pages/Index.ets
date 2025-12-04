
import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos'
import { AVVolumePanel } from '@kit.AudioKit';
import { emitter } from '@kit.BasicServicesKit';

let storage = LocalStorage.getShared()
const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS'

// 音量控制事件 ID
const VOLUME_CONTROL_EVENT_ID = 10001;

@Entry(storage)
@Component
struct Index {
  private context = getContext(this) as common.UIAbilityContext
  @LocalStorageLink('viewId') viewId: string = "";
  // 系统音量控制
  @State systemVolume: number = 0;

  aboutToAppear(): void {
    // 订阅音量控制事件
    emitter.on({ eventId: VOLUME_CONTROL_EVENT_ID }, (eventData: emitter.EventData) => {
      if (eventData.data && typeof eventData.data.volume === 'number') {
        this.systemVolume = eventData.data.volume as number;
      }
    });
  }

  aboutToDisappear(): void {
    // 取消订阅
    emitter.off(VOLUME_CONTROL_EVENT_ID);
  }

  build() {
    Stack() {
      // Flutter 页面
      FlutterPage({ viewId: this.viewId })
      
      // 隐藏的系统音量面板（放在屏幕外，不拦截触摸事件）
      AVVolumePanel({
        volumeLevel: this.systemVolume,
        volumeParameter: {
          position: {
            x: -1000,
            y: -1000
          }
        }
      })
        .hitTestBehavior(HitTestMode.None)
        .width(1)
        .height(1)
        .position({ x: -1000, y: -1000 })
    }
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS)
    return true
  }
}