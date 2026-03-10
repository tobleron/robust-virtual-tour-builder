let escapeHtml = (raw: string): string =>
  raw
  ->String.replaceRegExp(/&/g, "&amp;")
  ->String.replaceRegExp(/</g, "&lt;")
  ->String.replaceRegExp(/>/g, "&gt;")
  ->String.replaceRegExp(/"/g, "&quot;")
  ->String.replaceRegExp(/'/g, "&#39;")

let buildBannerHtml = (
  ~marketingBody: string,
  ~marketingShowRent: bool,
  ~marketingShowSale: bool,
): string => {
  let hasMarketingBanner = marketingShowRent || marketingShowSale || marketingBody != ""
  if hasMarketingBanner {
    let rentChipHtml = if marketingShowRent {
      `<span class="viewer-marketing-chip-export viewer-marketing-chip-rent-export viewer-marketing-chip-left-export viewer-marketing-chip-left-only-export">RENT</span>`
    } else {
      ""
    }
    let saleChipHtml = if marketingShowSale {
      `<span class="viewer-marketing-chip-export viewer-marketing-chip-sale-export ${if (
          !marketingShowRent
        ) {
          "viewer-marketing-chip-left-export"
        } else {
          ""
        }}">SALE</span>`
    } else {
      ""
    }
    let textWrapHtml = if marketingBody != "" {
      `<span class="viewer-marketing-text-wrap-export ${if (
          !marketingShowRent && !marketingShowSale
        ) {
          "viewer-marketing-text-wrap-export-left"
        } else {
          ""
        }}"><span class="viewer-marketing-banner-text-export">${escapeHtml(
          marketingBody,
        )}</span></span>`
    } else {
      ""
    }
    `<div id="viewer-marketing-banner-export">${rentChipHtml}${saleChipHtml}${textWrapHtml}</div>`
  } else {
    ""
  }
}

let buildPortraitHtml = (
  ~marketingShowRent: bool,
  ~marketingShowSale: bool,
  ~marketingPhone1: string,
  ~marketingPhone2: string,
): string => {
  let hasPortraitMarketing =
    marketingShowRent || marketingShowSale || marketingPhone1 != "" || marketingPhone2 != ""
  if hasPortraitMarketing {
    let portraitBadgeRentHtml = if marketingShowRent {
      `<span class="viewer-marketing-portrait-badge-export viewer-marketing-portrait-badge-rent-export">RENT</span>`
    } else {
      ""
    }
    let portraitBadgeSaleHtml = if marketingShowSale {
      `<span class="viewer-marketing-portrait-badge-export viewer-marketing-portrait-badge-sale-export">SALE</span>`
    } else {
      ""
    }
    let portraitPhone1Html = if marketingPhone1 != "" {
      `<span class="viewer-marketing-portrait-phone-export">${escapeHtml(marketingPhone1)}</span>`
    } else {
      ""
    }
    let portraitPhone2Html = if marketingPhone2 != "" {
      `<span class="viewer-marketing-portrait-phone-export">${escapeHtml(marketingPhone2)}</span>`
    } else {
      ""
    }
    `<div id="viewer-marketing-portrait-export"><div class="viewer-marketing-portrait-badges-export">${portraitBadgeRentHtml}${portraitBadgeSaleHtml}</div><div class="viewer-marketing-portrait-phones-export">${portraitPhone1Html}${portraitPhone2Html}</div></div>`
  } else {
    ""
  }
}
