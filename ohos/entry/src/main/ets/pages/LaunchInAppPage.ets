import router from '@ohos.router';
import webview from '@ohos.web.webview';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
struct LaunchInAppPage {
  private url: string = '';
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['url']) {
      this.url = params['url'] as string;
    }

    // 监听关闭事件
    emitter.on("closeWebView", () => {
      router.back();
    });
  }

  aboutToDisappear() {
    emitter.off("closeWebView");
  }

  build() {
    Column() {
      // 顶部工具栏
      Row() {
        Button('返回')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 10 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#F5F5F5')

      // WebView
      Web({ src: this.url, controller: this.controller })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}
