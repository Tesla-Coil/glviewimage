{
  Copyright 2013-2017 Michalis Kamburelis.

  This file is part of "glViewImage".

  "glViewImage" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "glViewImage" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "glViewImage"; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA

  ----------------------------------------------------------------------------
}

{ File formats understood by CastleImages unit.
  This must be manually synchronized with
  ~/sources/castle-engine/castle-engine/src/images/castleimages_file_formats.inc
  now. }
unit CastleImagesFormats;

interface

type
  { Possible image file format. }
  TImageFormat = (
    { We handle PNG file format fully, both reading and writing,
      through the libpng library.

      This format supports a full alpha channel.
      Besides PSD, this is the only format that allows full-range
      (partial transparency) alpha channel.

      Trying to read / write PNG file when libpng is not installed
      (through LoadImage, LoadEncodedImage, SaveImage, LoadPNG, SavePNG and others)
      will raise exception ELibPngNotAvailable. Note that the check
      for availability of libpng is done only once you try to load/save PNG file.
      You can perfectly compile and even run your programs without
      PNG installed, until you try to load/save PNG format. }
    ifPNG,

    { We handle uncompressed BMP images. }
    ifBMP,

    ifPPM,

    { Image formats below are supported by FPImage. }
    ifJPEG, ifGIF, ifTGA, ifXPM, ifPSD, ifPCX, ifPNM,

    { We handle fully DDS (DirectDraw Surface) image format.
      See also TCompositeImage class in CastleCompositeImage unit,
      that exposes even more features of the DDS image format. }
    ifDDS,
    ifKTX,

    { High-dynamic range image format, originally used by Radiance.
      See e.g. the pfilt and ximage programs from the Radiance package
      for processing such images.

      The float color values are encoded smartly as 4 bytes:
      3 mantisas for RGB and 1 byte for an Exponent.
      This is the Greg Ward's RGBE color encoding described in the
      "Graphic Gems" (gem II.5). This allows high floating-point-like precision,
      and possibility to encode any value >= 0 (not necessarily <= 1),
      keeping the pixel only 4 bytes long.

      Encoding a color values with float precision is very useful.
      Otherwise, when synthesized / photographed images are
      very dark / very bright, simply encoding them in traditional fixed-point
      pixel format looses color precision. So potentially important but small
      differences are lost in fixed-point formats.
      And color values are clamped to [0..1] range.
      On the other hand, keeping colors as floats preserves
      everything, and allows to process images later.

      It's most useful and natural to load/save these files as TRGBFloatImage,
      this way you keep the floating-point precision inside memory.
      However, you can also load/convert such image format
      to normal 8-bits image formats (like TRGBImage),
      if you're Ok with losing some of the precision. }
    ifRGBE,

    ifIPL,

    { Image formats below are supported
      by converting them  "under the hood" with ImageMagick.
      This is available only if this unit is compiled with FPC
      (i.e. not with Delphi) on platforms where ExecuteProcess is
      implemented. And ImageMagick must be installed and available on $PATH. }
    ifTIFF, ifSGI, ifJP2, ifEXR
  );
  TImageFormats = set of TImageFormat;

  { Index of TImageFormatInfo.MimeTypes array and
    type for TImageFormatInfo.MimeTypesCount.
    Implies that TImageFormatInfo.MimeTypes is indexed from 1,
    TImageFormatInfo.MimeTypesCount must be >= 1,
    so each file format must have at least one
    (treated as "default" in some cases) MIME type. }
  TImageFormatInfoMimeTypesCount = 1..6;

  { A type to index TImageFormatInfo.Exts array and also for TImageFormatInfo.ExtsCount.
    So TImageFormatInfo.Exts array is indexed from 1,
    and TImageFormatInfo.ExtsCount must be >= 1, so each file format must have at least one
    (treated as "default" in some cases) file extension. }
  TImageFormatInfoExtsCount = 1..3;

  TImageFormatInfo = record
    { Human-readable format name.

      Note that this is supposed to be shown to normal user,
      in save dialog boxes etc. So it should be short and concise. I used to
      have here long format names like @code(JFIF, JPEG File Interchange Format) or
      @code(PNG, Portable Network Graphic), but they are too ugly, and unnecessarily
      resolving format abbrevs. For example, most users probably used JPEG,
      but not many have to know, or understand, that actually this is image format JFIF;
      these are technical and historical details that are not needed for normal usage of image
      operations.

      Saying it directly, I want to keep this FormatName short and concise.
      This is not a place to educate users what some abbrev means.
      This is a place to "name" each file format in the most natural way, which
      usually means to only slightly rephrase typical file format extension.

      In practice, I now copy descriptions from English GIMP open dialog. }
    FormatName: string;

    MimeTypesCount: TImageFormatInfoMimeTypesCount;

    { MIME types recognized as this image file format.
      First MIME type is the default for this file format
      (some procedures make use of it). }
    MimeTypes: array [TImageFormatInfoMimeTypesCount] of string;

    ExtsCount: TImageFormatInfoExtsCount;

    { File extensions for this image type.
      First file extension is default, which is used for some routines.
      Must be lowercase.

      This is used e.g. to construct file filters in open/save dialogs.
      Together with MimeTypes it is also used by URIMimeType to map
      file extension into a MIME type. An extension matching one of Exts
      values implicates the default MIME type for this format (MimeTypes[1]).

      Note that to cooperate nicely with network URLs
      (when server may report MIME type) and data URIs, most of the code
      should operate using MIME types instead of file extensions.
      So usually you are more interested in MimeTypes than Exts. }
    Exts: array [TImageFormatInfoExtsCount] of string;

    { Has Save function ("Assigned(Save)" in CastleImages) }
    HasSave: boolean;
  end;

const
  { Information about supported image formats. }
  ImageFormatInfos: array [TImageFormat] of TImageFormatInfo =
  ( { The order on this list matters --- it determines the order of filters
      for open/save dialogs.
      First list most adviced and well-known formats, starting from lossless. }

    { Portable Network Graphic } { }
    ( FormatName: 'PNG image';
      MimeTypesCount: 1;
      MimeTypes: ('image/png', '', '', '', '', '');
      ExtsCount: 1; Exts: ('png', '', '');
      HasSave: true
    ),
    ( FormatName: 'Windows BMP image';
      MimeTypesCount: 1;
      MimeTypes: ('image/bmp', '', '', '', '', '');
      ExtsCount: 1; Exts: ('bmp', '', '');
      HasSave: true
    ),
    { Portable Pixel Map } { }
    ( FormatName: 'PPM image';
      MimeTypesCount: 1;
      MimeTypes: ('image/x-portable-pixmap', '', '', '', '', '');
      ExtsCount: 1; Exts: ('ppm', '', '');
      HasSave: true
    ),
    { JFIF, JPEG File Interchange Format } { }
    ( FormatName: 'JPEG image';
      MimeTypesCount: 2;
      MimeTypes: ('image/jpeg', 'image/jpg', '', '', '', '');
      ExtsCount: 3; Exts: ('jpg', 'jpeg', 'jpe');
      HasSave: true
    ),
    { Graphics Interchange Format } { }
    ( FormatName: 'GIF image';
      MimeTypesCount: 1;
      MimeTypes: ('image/gif', '', '', '', '', '');
      ExtsCount: 1; Exts: ('gif', '', '');
      HasSave: false
    ),
    ( FormatName: 'TarGA image';
      MimeTypesCount: 2;
      MimeTypes: ('image/x-targa', 'image/x-tga', '', '', '', '');
      ExtsCount: 2; Exts: ('tga', 'tpic', '');
      HasSave: false
    ),
    ( FormatName: 'XPM image';
      MimeTypesCount: 1;
      MimeTypes: ('image/x-xpixmap', '', '', '', '', '');
      ExtsCount: 1; Exts: ('xpm', '', '');
      HasSave: false
    ),
    ( FormatName: 'PSD image';
      MimeTypesCount: 4;
      MimeTypes: ('image/photoshop', 'image/x-photoshop', 'image/psd', 'application/photoshop', '', '');
      ExtsCount: 1; Exts: ('psd', '', '');
      HasSave: false
    ),
    ( FormatName: 'ZSoft PCX image';
      MimeTypesCount: 5;
      MimeTypes: ('image/pcx', 'application/pcx', 'application/x-pcx', 'image/x-pc-paintbrush', 'image/x-pcx', '');
      ExtsCount: 1; Exts: ('pcx', '', '');
      HasSave: false
    ),
    ( FormatName: 'PNM image';
      MimeTypesCount: 6;
      MimeTypes: ('image/x-portable-anymap', 'image/x-portable-graymap', 'image/x-pgm', 'image/x-portable-bitmap', 'image/pbm', 'image/x-pbm');
      ExtsCount: 3; Exts: ('pnm', 'pgm', 'pbm');
      HasSave: false
    ),

    { Direct Draw Surface } { }
    ( FormatName: 'DDS image';
      MimeTypesCount: 1;
      MimeTypes: ('image/x-dds', '', '', '', '', '');
      ExtsCount: 1; Exts: ('dds', '', '');
      HasSave: true
    ),

    { Khronos KTX } { }
    ( FormatName: 'Khronos KTX image';
      MimeTypesCount: 1;
      MimeTypes: ('image/ktx', '', '', '', '', '');
      ExtsCount: 1; Exts: ('ktx', '', '');
      HasSave: false
    ),

    { Image formats not well known. }

    ( FormatName: 'RGBE (RGB+Exponent) image';
      MimeTypesCount: 1;
      MimeTypes: ('image/vnd.radiance', '', '', '', '', '');
      ExtsCount: 3; Exts: ('rgbe', 'pic', 'hdr');
      HasSave: true
    ),
    ( FormatName: 'IPLab image';
      MimeTypesCount: 1;
      { ipl MIME type invented by Kambi, to make it unique to communicate image format for LoadImage } { }
      MimeTypes: ('image/x-ipl', '', '', '', '', '');
      ExtsCount: 1; Exts: ('ipl', '', '');
      HasSave: false
    ),

    { Image formats loaded using ImageMagick's convert.
      Placed at the end of the list, to be at the end of open/save dialogs
      filters, since there's a large chance they will not work,
      if user didn't install ImageMagick. } { }

    ( FormatName: 'TIFF image';
      MimeTypesCount: 1;
      MimeTypes: ('image/tiff', '', '', '', '', '');
      ExtsCount: 2; Exts: ('tiff', 'tif', '');
      HasSave: false
    ),
    ( FormatName: 'SGI image';
      MimeTypesCount: 3;
      MimeTypes: ('image/sgi', 'image/x-sgi', 'image/x-sgi-rgba', '', '', '');
      ExtsCount: 1; Exts: ('sgi', '', '');
      HasSave: false
    ),
    ( FormatName: 'JPEG 2000 image';
      MimeTypesCount: 4;
      MimeTypes: ('image/jp2', 'image/jpeg2000', 'image/jpeg2000-image', 'image/x-jpeg2000-image', '', '');
      ExtsCount: 1; Exts: ('jp2', '', '');
      HasSave: false
    ),
    ( FormatName: 'EXR image';
      MimeTypesCount: 1;
      MimeTypes: ('image/x-exr', '', '', '', '', '');
      ExtsCount: 1; Exts: ('exr', '', '');
      HasSave: false
    )
  );

implementation

end.
