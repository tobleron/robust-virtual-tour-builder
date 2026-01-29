open Vitest
open ExifReportGenerator.Utils

/* Mocks */
type mockFn
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

%%raw(`
  import { vi } from 'vitest';

  // Mock UrlUtils
  vi.mock('../../src/utils/UrlUtils.bs.js', () => {
    return {
      safeCreateObjectURL: vi.fn(() => "blob:mock-url")
    };
  });

  // Mock global URL methods
  global.URL.revokeObjectURL = vi.fn();
`)

describe("ExifReportGeneratorUtils", () => {
  describe("generateProjectName", () => {
    test(
      "generates name from address and date",
      t => {
        let addr = Some("123 Main St, Los Angeles, CA")
        let dateTime = Some("2025:01:15 14:30:00")
        let name = generateProjectName(addr, dateTime)

        switch name {
        | Some(n) => t->expect(String.startsWith(n, "123_Main_St_150125_1430"))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    test(
      "handles unicode characters in address",
      t => {
        let addr = Some("Straße 123, München, Bayern")
        let dateTime = Some("2024:12:31 23:59:59")
        let name = generateProjectName(addr, dateTime)

        switch name {
        | Some(n) =>
          t->expect(String.includes(n, "Stra"))->Expect.toBe(true)
          t->expect(String.includes(n, "311224_2359"))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    test(
      "falls back to 'Tour' when address is missing",
      t => {
        let dateTime = Some("2023:05:20 10:00:00")
        let name = generateProjectName(None, dateTime)

        switch name {
        | Some(n) => t->expect(String.startsWith(n, "Tour_200523_1000"))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )

    test(
      "falls back to current time when date is missing or invalid",
      t => {
        let addr = Some("Office")
        let name = generateProjectName(addr, None)

        let now = Date.make()
        let day = String.padStart(Belt.Int.toString(Date.getDate(now)), 2, "0")
        let month = String.padStart(Belt.Int.toString(Date.getMonth(now) + 1), 2, "0")

        switch name {
        | Some(n) => t->expect(String.startsWith(n, "Office_" ++ day ++ month))->Expect.toBe(true)
        | None => t->expect(true)->Expect.toBe(false)
        }
      },
    )
  })

  describe("downloadExifReport", () => {
    test(
      "creates download link and clicks it",
      t => {
        let clickMock = %raw(`vi.fn()`)
        let setAttributeMock = %raw(`vi.fn()`)
        let appendChildMock = %raw(`vi.fn()`)
        let removeMock = %raw(`vi.fn()`)

        let mockElement = {
          "click": clickMock,
          "setAttribute": setAttributeMock,
          "remove": removeMock,
        }

        let setupMocks: ({..}, mockFn) => unit = %raw(`
        function(elem, append) {
           vi.spyOn(document, 'createElement').mockReturnValue(elem);
           vi.spyOn(document.body, 'appendChild').mockImplementation(append);
        }
      `)

        setupMocks(mockElement, appendChildMock)

        let filename = downloadExifReport("report content")

        t->expect(String.startsWith(filename, "EXIF_METADATA_"))->Expect.toBe(true)
        t->expect(String.endsWith(filename, ".txt"))->Expect.toBe(true)

        let _ = %raw(`expect(setAttributeMock).toHaveBeenCalledWith("download", filename)`)
        let _ = %raw(`expect(setAttributeMock).toHaveBeenCalledWith("href", "blob:mock-url")`)
        let _ = %raw(`expect(clickMock).toHaveBeenCalled()`)
        // Not verifying remove as implementation depends on ReBindings
      },
    )
  })
})
