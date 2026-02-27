use super::*;

#[test]
fn teaser_output_format_parses_mp4_and_defaults_to_webm() {
    assert_eq!(TeaserOutputFormat::from_str("mp4"), TeaserOutputFormat::Mp4);
    assert_eq!(TeaserOutputFormat::from_str("MP4"), TeaserOutputFormat::Mp4);
    assert_eq!(
        TeaserOutputFormat::from_str("webm"),
        TeaserOutputFormat::Webm
    );
    assert_eq!(
        TeaserOutputFormat::from_str("unexpected-format"),
        TeaserOutputFormat::Webm
    );
}
