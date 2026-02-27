open ReBindings
open SharedTypes
open Types

let extractExifFromFile = async (file: File.t): result<exifMetadata, string> => {
  switch await ExifParser.extractExifTagsPreferred(File(file)) {
  | Ok((exif, _)) => Ok(exif)
  | Error(msg) => Error(msg)
  }
}
