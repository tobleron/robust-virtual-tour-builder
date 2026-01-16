/* tests/TestRunner.res */
%%raw(`
  if (typeof globalThis.window === 'undefined') {
    globalThis.window = {
      location: { hostname: 'localhost', toString: () => 'http://localhost' },
      screen: { width: 1920, height: 1080 },
      devicePixelRatio: 1,
      navigator: { 
        userAgent: 'NodeTest', 
        platform: 'Node', 
        hardwareConcurrency: 8, 
        deviceMemory: 16,
        serviceWorker: {
          register: () => Promise.resolve({}),
          getRegistrations: () => Promise.resolve([]),
          addEventListener: () => {}
        }
      },
      addEventListener: () => {},
      removeEventListener: () => {},
      pannellumViewer: null
    };
    globalThis.document = {
      createElement: (tag) => ({ 
        tag: tag,
        getContext: () => ({ 
          getExtension: () => null, 
          getParameter: () => 'mock',
          fillRect: () => {},
          beginPath: () => {},
          stroke: () => {},
          fill: () => {},
          save: () => {},
          restore: () => {},
        }),
        style: {},
        appendChild: () => {},
        setAttribute: () => {},
        classList: { add: () => {}, remove: () => {}, contains: () => false, toggle: () => {} }
      }),
      getElementById: () => null,
      querySelector: () => null,
      querySelectorAll: () => [],
      addEventListener: () => {},
      body: { 
        appendChild: () => {},
        style: {}
      }
    };
    globalThis.navigator = globalThis.window.navigator;
    globalThis.location = globalThis.window.location;
    globalThis.screen = globalThis.window.screen;
    globalThis.FormData = class { append() {} };
    globalThis.Blob = class { constructor() { this.size = 0; this.type = ''; } };
    // Don't mock Date.toISOString as it's used in ExifReportGeneratorTest which expects current date
  }
`)

Console.log("Starting Frontend Unit Tests...")

GeoUtilsTest.run()
LoggerTest.run()
SimulationSystemTest.run()
InputSystemTest.run()
TourLogicTest.run()
PathInterpolationTest.run()
ReducerTest.run()
ReducerHelpersTest.run()
JsonTypesTest.run()
SceneReducerTest.run()
HotspotReducerTest.run()
ExifParserTest.run()
AudioManagerTest.run()
ExifReportGeneratorTest.run()
SharedTypesTest.run()
ReBindingsTest.run()
BackendApiTest.run()
ProjectManagerTest.run()
DownloadSystemTest.run()
ProjectDataTest.run()
ResizerTest.run()
UploadProcessorTest.run()
VideoEncoderTest.run()
TeaserManagerTest.run()
TeaserRecorderTest.run()
TourTemplateAssetsTest.run()
TourTemplateScriptsTest.run()
TourTemplateStylesTest.run()
ExporterTest.run()
LazyLoadTest.run()
ProgressBarTest.run()
StateInspectorTest.run()
ServiceWorkerTest.run()
NavigationTest.run()
MainTest.run()
ViewerLoaderTest.run()

Console.log("All frontend tests passed successfully! 🎉")
