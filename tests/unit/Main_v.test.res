// @efficiency: infra-adapter
open Vitest

describe("Main", () => {
  test("Navigator bindings are accessible", _ => {
    /* Verified in node-setup.js mocks */
    let _ = (
      Main.Navigator.userAgent,
      Main.Navigator.platform,
      Main.Navigator.hardwareConcurrency,
      Main.Navigator.deviceMemory,
    )
  })

  test("Screen bindings are accessible", _ => {
    let _ = (Main.Screen.width, Main.Screen.height, Main.Screen.devicePixelRatio)
  })

  test("WebGL bindings are accessible", _ => {
    /* This just ensures the compiler sees these as valid modules and externals */
    let _ = (Main.WebGL.getContext, Main.WebGL.getExtension, Main.WebGL.getParameter)
  })

  test("ViewerClickEvent detail access", t => {
    let mockEvent: Main.ViewerClickEvent.t = Obj.magic({
      "detail": {
        "pitch": 10.5,
        "yaw": 20.5,
        "camPitch": 30.5,
        "camYaw": 40.5,
        "camHfov": 50.5,
      },
    })
    let detail = Main.ViewerClickEvent.detail(mockEvent)

    t->expect(detail.pitch)->Expect.toBe(10.5)
    t->expect(detail.yaw)->Expect.toBe(20.5)
    t->expect(detail.camPitch)->Expect.toBe(30.5)
    t->expect(detail.camYaw)->Expect.toBe(40.5)
    t->expect(detail.camHfov)->Expect.toBe(50.5)
  })

  test("init function is accessible", _ => {
    let _ = Main.init
  })
})
