codeunit 50901 "E-Invoice PDF Fixtures"
{
    // Three real PDF files, base64-encoded. Both carrier documents embed a
    // Cross-Industry Invoice XML the PDF/A-3 way: an /EmbeddedFiles name tree plus
    // an /AF entry whose filespec carries /AFRelationship /Alternative. That
    // relationship - not /Data - is what Factur-X/ZUGFeRD reserves for the invoice
    // XML that stands in for the printed page, and what Business Central itself
    // writes, so a resolver that filters on it still finds these attachments.
    // The plain scan embeds nothing.

    procedure FacturXCarrierPdf(var PdfTempBlob: Codeunit "Temp Blob")
    var
        Base64Text: TextBuilder;
    begin
        AppendFacturXCarrier(Base64Text);
        DecodeInto(Base64Text.ToText(), PdfTempBlob);
    end;

    procedure ZugferdCarrierPdf(var PdfTempBlob: Codeunit "Temp Blob")
    var
        Base64Text: TextBuilder;
    begin
        AppendZugferdCarrier(Base64Text);
        DecodeInto(Base64Text.ToText(), PdfTempBlob);
    end;

    procedure PlainScanPdf(var PdfTempBlob: Codeunit "Temp Blob")
    var
        Base64Text: TextBuilder;
    begin
        AppendPlainScan(Base64Text);
        DecodeInto(Base64Text.ToText(), PdfTempBlob);
    end;

    local procedure DecodeInto(Base64Text: Text; var PdfTempBlob: Codeunit "Temp Blob")
    var
        Base64Convert: Codeunit "Base64 Convert";
        PdfOutStr: OutStream;
    begin
        Clear(PdfTempBlob);
        PdfTempBlob.CreateOutStream(PdfOutStr);
        Base64Convert.FromBase64(Base64Text, PdfOutStr);
    end;

    local procedure AppendFacturXCarrier(var Base64Text: TextBuilder)
    begin
        Base64Text.Append('JVBERi0xLjcKJcK1wrYKJSBXcml0dGVuIGJ5IE11UERGIDEuMjcuMgoKMSAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgMiAwIFIvSW5m');
        Base64Text.Append('bzw8L1Byb2R1Y2VyKE11UERGIDEuMjcuMik+Pi9OYW1lczw8L0VtYmVkZGVkRmlsZXM8PC9OYW1lc1soZmFjdHVyLXgueG1sKTExIDAgUl0+');
        Base64Text.Append('Pj4+L01ldGFkYXRhIDggMCBSL1BhZ2VNb2RlL1VzZUF0dGFjaG1lbnRzL0FGWzExIDAgUl0+PgplbmRvYmoKCjIgMCBvYmoKPDwvVHlwZS9Q');
        Base64Text.Append('YWdlcy9Db3VudCAyL0tpZHNbMyAwIFIgNSAwIFJdPj4KZW5kb2JqCgozIDAgb2JqCjw8L1R5cGUvUGFnZS9NZWRpYUJveFswIDAgNTk1IDg0');
        Base64Text.Append('Ml0vUm90YXRlIDAvUmVzb3VyY2VzPDwvRm9udDw8L2hlbHYgNCAwIFI+Pj4+L1BhcmVudCAyIDAgUi9Db250ZW50cyA5IDAgUj4+CmVuZG9i');
        Base64Text.Append('agoKNCAwIG9iago8PC9UeXBlL0ZvbnQvU3VidHlwZS9UeXBlMS9CYXNlRm9udC9IZWx2ZXRpY2EvRW5jb2RpbmcvV2luQW5zaUVuY29kaW5n');
        Base64Text.Append('Pj4KZW5kb2JqCgo1IDAgb2JqCjw8L1R5cGUvUGFnZS9NZWRpYUJveFswIDAgNTk1IDg0Ml0vUm90YXRlIDAvUmVzb3VyY2VzPDwvRm9udDw8');
        Base64Text.Append('L2hlbHYgNCAwIFI+Pj4+L1BhcmVudCAyIDAgUi9Db250ZW50cyAxMCAwIFI+PgplbmRvYmoKCjYgMCBvYmoKPDwvVGl0bGUoSW52b2ljZSBJ');
        Base64Text.Append('TlYtMTAwMSkvQXV0aG9yKFRyeUFMIEZpeHR1cmUgR2VuZXJhdG9yKS9Qcm9kdWNlcihUcnlBTCkvQ3JlYXRvcihUcnlBTCk+PgplbmRvYmoK');
        Base64Text.Append('CjcgMCBvYmoKPDwvVHlwZS9FbWJlZGRlZEZpbGUvTGVuZ3RoIDY0NC9GaWx0ZXIvRmxhdGVEZWNvZGUvREwgMTgyOS9QYXJhbXM8PC9TaXpl');
        Base64Text.Append('IDE4MjkvQ3JlYXRpb25EYXRlKEQ6MjAyNjA4MjMwMjE1MjUrMDMnMDAnKS9Nb2REYXRlKEQ6MjAyNjA4MjMwMjE1MjUrMDMnMDAnKT4+Pj4K');
        Base64Text.Append('c3RyZWFtCnjanVXvT+JAEP3uX9HUz0ALol4DNQieknicoXDf1+6Im7S7vf2h9L932i1IC4h3CWlC35s3s29mtoObdZo4byAVE3zo+m3PdYDH');
        Base64Text.Append('gjK+GrrLxc/WtXsTng2kSoOxFEpNOTVKy3zK3wSLwcFwrgKEh66RPDDFD2LAZwwvJNYBJZoEShNOiaQHNQLfw6yVEPmm0ByMIs8JjFYrCSui');
        Base64Text.Append('4dYoxqEQfxEyJRrPc8c10/muvKH6e/JL/teQhL0woBMEFnlmywzPHKc0424dvxK+QljEJgWux4JrWOuCUFBIGtwbRiHBoqIMYitV5z4RpIEG');
        Base64Text.Append('aYOqsOkkLCqMgbfBBMD9yx89P+h6/tV5LNIsYYTr84JRlG1ka13Q/MwLnoli8Xsy6FQqtpLOv5eCMSdOeNiCnbNj+unsTwst8xv1FH8KO8eC');
        Base64Text.Append('Qti79iy8fbMjoZQBNB8WLIWtQ9jBYPMy0hLH1LH9xuH1um7Y9bp9z/f7g84+c9eRPfUjh96eNjJZluTjV8L4QhIK+OAKO4BztlP0CEksLgbz');
        Base64Text.Append('AZAkS+oIRxQ+DaqoESRJRUD3db4BK3iG/QhnQtJ3xqnzRDIG0rlPnx9s/SW8ket8pVeq3Zr8VK7x/PdsGTlTbLLk5f6QxHnUtH0s4UFNC33H');
        Base64Text.Append('huN+TXBU8UrKnc4pZgRaJ/vWVhfL2EiJl1leDtbdcl51/gBY68tmRRoZbNpfgoMmMo9Mai+ZhpWPuGQLoUkySoXBsnyvd9W+6NvUTbAeuiDr');
        Base64Text.Append('W1xhdTT8EKEucY9DSWvx3d5Fu39Z3QJNtJG/QJ4kZITRitD1vLa3WdF9uB4/MTgIeXkpb4v/TL6H1of3f0z/Ytbqg2F3+8sNtpRDn6fw7AMV');
        Base64Text.Append('MmoMCmVuZHN0cmVhbQplbmRvYmoKCjggMCBvYmoKPDwvVHlwZS9NZXRhZGF0YS9TdWJ0eXBlL1hNTC9MZW5ndGggOTIzPj4Kc3RyZWFtCjw/');
        Base64Text.Append('eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+Cjx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6');
        Base64Text.Append('bWV0YS8iPgogIDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+CiAgICA8');
        Base64Text.Append('cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczpwZGZhaWQ9Imh0dHA6Ly93d3cuYWlpbS5vcmcvcGRmYS9ucy9pZC8iPgogICAg');
        Base64Text.Append('ICA8cGRmYWlkOnBhcnQ+MzwvcGRmYWlkOnBhcnQ+CiAgICAgIDxwZGZhaWQ6Y29uZm9ybWFuY2U+QjwvcGRmYWlkOmNvbmZvcm1hbmNlPgog');
        Base64Text.Append('ICAgPC9yZGY6RGVzY3JpcHRpb24+CiAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3Jn');
        Base64Text.Append('L2RjL2VsZW1lbnRzLzEuMS8iPgogICAgICA8ZGM6dGl0bGU+PHJkZjpBbHQ+PHJkZjpsaSB4bWw6bGFuZz0ieC1kZWZhdWx0Ij5JbnZvaWNl');
        Base64Text.Append('IElOVi0xMDAxPC9yZGY6bGk+PC9yZGY6QWx0PjwvZGM6dGl0bGU+CiAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgIDxyZGY6RGVzY3JpcHRp');
        Base64Text.Append('b24gcmRmOmFib3V0PSIiIHhtbG5zOmZ4PSJ1cm46ZmFjdHVyLXg6cGRmYTpDcm9zc0luZHVzdHJ5RG9jdW1lbnQ6aW52b2ljZToxcDAjIj4K');
        Base64Text.Append('ICAgICAgPGZ4OkRvY3VtZW50VHlwZT5JTlZPSUNFPC9meDpEb2N1bWVudFR5cGU+CiAgICAgIDxmeDpEb2N1bWVudEZpbGVOYW1lPmZhY3R1');
        Base64Text.Append('ci14LnhtbDwvZng6RG9jdW1lbnRGaWxlTmFtZT4KICAgICAgPGZ4OlZlcnNpb24+MS4wPC9meDpWZXJzaW9uPgogICAgICA8Zng6Q29uZm9y');
        Base64Text.Append('bWFuY2VMZXZlbD5CQVNJQyBXTDwvZng6Q29uZm9ybWFuY2VMZXZlbD4KICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogIDwvcmRmOlJERj4KPC94');
        Base64Text.Append('OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9InciPz4KCmVuZHN0cmVhbQplbmRvYmoKCjkgMCBvYmoKPDwvTGVuZ3RoIDE0NS9GaWx0ZXIvRmxh');
        Base64Text.Append('dGVEZWNvZGU+PgpzdHJlYW0KeJyNzL0OgjAUhuFb+UYd1J5Ci64mRGEgao4uxqFKjST8SBGMd6/BxNGQd36fGkue3WzegQh8BUF8IgQSgZLg');
        Base64Text.Append('4jhKKpc+szLFxtwz67AqzuvxiWOEjC3qP4Dn90BUdlV2sYiSw4SEoGEz6e/cNK1NQQqxKVvjXpBCqkGEXsx7gquHyRHudyDp+VOlf/cbjWNC');
        Base64Text.Append('UAplbmRzdHJlYW0KZW5kb2JqCgoxMCAwIG9iago8PC9MZW5ndGggOTIvRmlsdGVyL0ZsYXRlRGVjb2RlPj4Kc3RyZWFtCnicK1RwCtHPSM0p');
        Base64Text.Append('UzA0VAhJUzBUMABCQwVzIwVzUyOFkNxojZDUotxihcS8FIXk/LyUzJLM/LxizdgQLwXXEIVAhUI8BhibgA0ISExPVTBSyE9TMILrAwC6tSAn');
        Base64Text.Append('CmVuZHN0cmVhbQplbmRvYmoKCjExIDAgb2JqCjw8L1R5cGUvRmlsZXNwZWMvRihmYWN0dXIteC54bWwpL1VGKGZhY3R1ci14LnhtbCkvRGVz');
        Base64Text.Append('YyhGYWN0dXItWCBlLWludm9pY2UpL0FGUmVsYXRpb25zaGlwL0FsdGVybmF0aXZlL0VGPDwvRiA3IDAgUi9VRiA3IDAgUj4+Pj4KZW5kb2Jq');
        Base64Text.Append('Cgp4cmVmCjAgMTIKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDQyIDAwMDAwIG4gCjAwMDAwMDAyMjYgMDAwMDAgbiAKMDAwMDAwMDI4');
        Base64Text.Append('NCAwMDAwMCBuIAowMDAwMDAwNDA4IDAwMDAwIG4gCjAwMDAwMDA0OTcgMDAwMDAgbiAKMDAwMDAwMDYyMiAwMDAwMCBuIAowMDAwMDAwNzMw');
        Base64Text.Append('IDAwMDAwIG4gCjAwMDAwMDE1NjEgMDAwMDAgbiAKMDAwMDAwMjU2MCAwMDAwMCBuIAowMDAwMDAyNzc0IDAwMDAwIG4gCjAwMDAwMDI5MzUg');
        Base64Text.Append('MDAwMDAgbiAKCnRyYWlsZXIKPDwvU2l6ZSAxMi9JbmZvIDYgMCBSL1Jvb3QgMSAwIFIvSURbPEMzQjIyQjYzM0YxREMyODVDMzhBQzM4NTRG');
        Base64Text.Append('QzNBRTMwPjw4MENCREYxMzk0REYyRERBNjBCRUI2MjBFRkU5MzVFMT5dPj4Kc3RhcnR4cmVmCjMwODAKJSVFT0YK');
    end;

    local procedure AppendZugferdCarrier(var Base64Text: TextBuilder)
    begin
        Base64Text.Append('JVBERi0xLjcKJcK1wrYKJSBXcml0dGVuIGJ5IE11UERGIDEuMjcuMgoKMSAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgMiAwIFIvSW5m');
        Base64Text.Append('bzw8L1Byb2R1Y2VyKE11UERGIDEuMjcuMik+Pi9OYW1lczw8L0VtYmVkZGVkRmlsZXM8PC9OYW1lc1soenVnZmVyZC1pbnZvaWNlLnhtbCkx');
        Base64Text.Append('MyAwIFJdPj4+Pi9NZXRhZGF0YSA5IDAgUi9QYWdlTW9kZS9Vc2VBdHRhY2htZW50cy9BRlsxMyAwIFJdPj4KZW5kb2JqCgoyIDAgb2JqCjw8');
        Base64Text.Append('L1R5cGUvUGFnZXMvQ291bnQgMy9LaWRzWzMgMCBSIDUgMCBSIDYgMCBSXT4+CmVuZG9iagoKMyAwIG9iago8PC9UeXBlL1BhZ2UvTWVkaWFC');
        Base64Text.Append('b3hbMCAwIDU5NSA4NDJdL1JvdGF0ZSAwL1Jlc291cmNlczw8L0ZvbnQ8PC9oZWx2IDQgMCBSPj4+Pi9QYXJlbnQgMiAwIFIvQ29udGVudHMg');
        Base64Text.Append('MTAgMCBSPj4KZW5kb2JqCgo0IDAgb2JqCjw8L1R5cGUvRm9udC9TdWJ0eXBlL1R5cGUxL0Jhc2VGb250L0hlbHZldGljYS9FbmNvZGluZy9X');
        Base64Text.Append('aW5BbnNpRW5jb2Rpbmc+PgplbmRvYmoKCjUgMCBvYmoKPDwvVHlwZS9QYWdlL01lZGlhQm94WzAgMCA1OTUgODQyXS9Sb3RhdGUgMC9SZXNv');
        Base64Text.Append('dXJjZXM8PC9Gb250PDwvaGVsdiA0IDAgUj4+Pj4vUGFyZW50IDIgMCBSL0NvbnRlbnRzIDExIDAgUj4+CmVuZG9iagoKNiAwIG9iago8PC9U');
        Base64Text.Append('eXBlL1BhZ2UvTWVkaWFCb3hbMCAwIDU5NSA4NDJdL1JvdGF0ZSAwL1Jlc291cmNlczw8L0ZvbnQ8PC9oZWx2IDQgMCBSPj4+Pi9QYXJlbnQg');
        Base64Text.Append('MiAwIFIvQ29udGVudHMgMTIgMCBSPj4KZW5kb2JqCgo3IDAgb2JqCjw8L1RpdGxlKEludm9pY2UgUkUtMjAyNC0wMDc3KS9BdXRob3IoVHJ5');
        Base64Text.Append('QUwgRml4dHVyZSBHZW5lcmF0b3IpL1Byb2R1Y2VyKFRyeUFMKS9DcmVhdG9yKFRyeUFMKT4+CmVuZG9iagoKOCAwIG9iago8PC9UeXBlL0Vt');
        Base64Text.Append('YmVkZGVkRmlsZS9MZW5ndGggNjExL0ZpbHRlci9GbGF0ZURlY29kZS9ETCAxODEzL1BhcmFtczw8L1NpemUgMTgxMy9DcmVhdGlvbkRhdGUo');
        Base64Text.Append('RDoyMDI2MDgyMzAyMTUyNSswMycwMCcpL01vZERhdGUoRDoyMDI2MDgyMzAyMTUyNSswMycwMCcpPj4+PgpzdHJlYW0KeNqdVdtu2kAQfc9X');
        Base64Text.Append('WLwDhjQCWeCIWylSmkbYfMDiHchK9q67lwj/fcc3ahtzaSVkCZ+ZMzNnzq4nr6cotL5AKib4tDPo2R0LeCAo48dpZ+d/7447r+7TRKrIWUih');
        Base64Text.Append('1IZTo7RMNvxLsAAsTOfKQXjaMZI7Jv1BAPgM4EAC7VCiiaM04ZRI2srhDGysWhCRB4m2YBTZhzA7HiUciYa5UYxDSn4QMiIa51lxzXRSpTdU');
        Base64Text.Append('P0a/478NCdmBAV0i4Cdx3qb7ZFmZGKtT8En4EWERmAi4Xgiu4aTTgDSERM7aMAohNuXFEORU9dgPgmGgQeZJRdpm6aYdHqApV5ntsFK32Hb2');
        Base64Text.Append('RLFg0i8S8+L9f6+OOXeGap+6Mi6W3666Q3v4rWvbo1Gjp/RPquJCUHCfx3YOn99UaJQygJqDzyI4C4OLc8qXnpboTitfM3rWHnbctOxgYD9P');
        Base64Text.Append('+peRVVUu2K8Mfp7YM3EcJotPwrgvCQV8cIV+QXtVmp5hEAtSP/4ADJJZ6AydCX9FKkI9CMMiADegkxIs4HfciZvKLpSw5gak2AM68mDN1vkE');
        Base64Text.Append('WUBJ2L/FmPHNTXK32vbX+86zNrhqybODQ0LrTdPetYKtnDn0iBDXFVuiYfEuSqz+vUgPtA4vxS1ulIWREm+xJLPWzlsWu28Ba5spD0qjQl72');
        Base64Text.Append('p+CgiUw8E+W3S0PKNzxqvtAknEXCYFsju2cXLm9C9USfnOZ4iNWV5Da4TrBGS9IqPB71XorsC6xRO0U+JMSE0SJgMDwnt6D19KVBByTZNVz0');
        Base64Text.Append('/XLu+wKre/Z/tL5hsbof8kN98+jmIW2fI/fpDzLmZ1sKZW5kc3RyZWFtCmVuZG9iagoKOSAwIG9iago8PC9UeXBlL01ldGFkYXRhL1N1YnR5');
        Base64Text.Append('cGUvWE1ML0xlbmd0aCA5Mjc+PgpzdHJlYW0KPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4K');
        Base64Text.Append('PHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyI+CiAgPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5');
        Base64Text.Append('LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4KICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnBkZmFpZD0iaHR0cDovL3d3');
        Base64Text.Append('dy5haWltLm9yZy9wZGZhL25zL2lkLyI+CiAgICAgIDxwZGZhaWQ6cGFydD4zPC9wZGZhaWQ6cGFydD4KICAgICAgPHBkZmFpZDpjb25mb3Jt');
        Base64Text.Append('YW5jZT5CPC9wZGZhaWQ6Y29uZm9ybWFuY2U+CiAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0');
        Base64Text.Append('PSIiIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyI+CiAgICAgIDxkYzp0aXRsZT48cmRmOkFsdD48cmRmOmxp');
        Base64Text.Append('IHhtbDpsYW5nPSJ4LWRlZmF1bHQiPkludm9pY2UgUkUtMjAyNC0wMDc3PC9yZGY6bGk+PC9yZGY6QWx0PjwvZGM6dGl0bGU+CiAgICA8L3Jk');
        Base64Text.Append('ZjpEZXNjcmlwdGlvbj4KICAgIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiIHhtbG5zOnpmPSJ1cm46ZmVyZDpwZGZhOkNyb3NzSW5k');
        Base64Text.Append('dXN0cnlEb2N1bWVudDppbnZvaWNlOjFwMCMiPgogICAgICA8emY6RG9jdW1lbnRUeXBlPklOVk9JQ0U8L3pmOkRvY3VtZW50VHlwZT4KICAg');
        Base64Text.Append('ICAgPHpmOkRvY3VtZW50RmlsZU5hbWU+enVnZmVyZC1pbnZvaWNlLnhtbDwvemY6RG9jdW1lbnRGaWxlTmFtZT4KICAgICAgPHpmOlZlcnNp');
        Base64Text.Append('b24+MS4wPC96ZjpWZXJzaW9uPgogICAgICA8emY6Q29uZm9ybWFuY2VMZXZlbD5CQVNJQzwvemY6Q29uZm9ybWFuY2VMZXZlbD4KICAgIDwv');
        Base64Text.Append('cmRmOkRlc2NyaXB0aW9uPgogIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cjw/eHBhY2tldCBlbmQ9InciPz4KCmVuZHN0cmVhbQplbmRvYmoK');
        Base64Text.Append('CjEwIDAgb2JqCjw8L0xlbmd0aCAxNDUvRmlsdGVyL0ZsYXRlRGVjb2RlPj4Kc3RyZWFtCnicjcy7DoJAFEXRXzmlFujM8BgsRYnRwkQdK0MB');
        Base64Text.Append('cokmwA3D4/tVTCwN2fVeDSKzfFA5QEqYAhLinYRW0L6CqW6zDdcdt4yoJ8sZ5aktsN7NE3NAbHBC84dwvZHY1wM/74Rz7CihPEcIracBMvgC');
        Base64Text.Append('bdtTDhdHHqjKyOLjTCKCVTgShru0xPWyRagXvvi9L7KjQ5QKZW5kc3RyZWFtCmVuZG9iagoKMTEgMCBvYmoKPDwvTGVuZ3RoIDg0L0ZpbHRl');
        Base64Text.Append('ci9GbGF0ZURlY29kZT4+CnN0cmVhbQp4nCtUcArRz0jNKVMwNFQISVMwVDAAQkMFcyMFc1MjhZDcaA2X1JzMstSiSoW8/JJUzdgQLwXXEIVA');
        Base64Text.Append('hUI8Oo1NwDoDEtNTFYwU8tMUjOH6AKtMHYoKZW5kc3RyZWFtCmVuZG9iagoKMTIgMCBvYmoKPDwvTGVuZ3RoIDg0L0ZpbHRlci9GbGF0ZURl');
        Base64Text.Append('Y29kZT4+CnN0cmVhbQp4nCtUcArRz0jNKVMwNFQISVMwVDAAQkMFcyMFc1MjhZDcaA2X1JzMstSiSoW8/JJUzdgQLwXXEIVAhUI8Oo1NwDoD');
        Base64Text.Append('EtNTFYwV8tMUjOH6AKtbHYsKZW5kc3RyZWFtCmVuZG9iagoKMTMgMCBvYmoKPDwvVHlwZS9GaWxlc3BlYy9GKHp1Z2ZlcmQtaW52b2ljZS54');
        Base64Text.Append('bWwpL1VGKHp1Z2ZlcmQtaW52b2ljZS54bWwpL0Rlc2MoWlVHRmVSRCBlLWludm9pY2UpL0FGUmVsYXRpb25zaGlwL0FsdGVybmF0aXZlL0VG');
        Base64Text.Append('PDwvRiA4IDAgUi9VRiA4IDAgUj4+Pj4KZW5kb2JqCgp4cmVmCjAgMTQKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDQyIDAwMDAwIG4g');
        Base64Text.Append('CjAwMDAwMDAyMzMgMDAwMDAgbiAKMDAwMDAwMDI5NyAwMDAwMCBuIAowMDAwMDAwNDIyIDAwMDAwIG4gCjAwMDAwMDA1MTEgMDAwMDAgbiAK');
        Base64Text.Append('MDAwMDAwMDYzNiAwMDAwMCBuIAowMDAwMDAwNzYxIDAwMDAwIG4gCjAwMDAwMDA4NzMgMDAwMDAgbiAKMDAwMDAwMTY3MSAwMDAwMCBuIAow');
        Base64Text.Append('MDAwMDAyNjc0IDAwMDAwIG4gCjAwMDAwMDI4ODkgMDAwMDAgbiAKMDAwMDAwMzA0MiAwMDAwMCBuIAowMDAwMDAzMTk1IDAwMDAwIG4gCgp0');
        Base64Text.Append('cmFpbGVyCjw8L1NpemUgMTQvSW5mbyA3IDAgUi9Sb290IDEgMCBSL0lEWzxDM0JGQzJBRUMzQTdDM0E3QzI4REMzQUQyNjU4QzNCOD48QjIx');
        Base64Text.Append('MTAwRkVDMTI2RTRGQzFBQ0Y2MTE0M0NCOTkwRUQ+XT4+CnN0YXJ0eHJlZgozMzUzCiUlRU9GCg==');
    end;

    local procedure AppendPlainScan(var Base64Text: TextBuilder)
    begin
        Base64Text.Append('JVBERi0xLjcKJcK1wrYKJSBXcml0dGVuIGJ5IE11UERGIDEuMjcuMgoKMSAwIG9iago8PC9UeXBlL0NhdGFsb2cvUGFnZXMgMiAwIFIvSW5m');
        Base64Text.Append('bzw8L1Byb2R1Y2VyKE11UERGIDEuMjcuMik+Pj4+CmVuZG9iagoKMiAwIG9iago8PC9UeXBlL1BhZ2VzL0NvdW50IDEvS2lkc1szIDAgUl0+');
        Base64Text.Append('PgplbmRvYmoKCjMgMCBvYmoKPDwvVHlwZS9QYWdlL01lZGlhQm94WzAgMCA1OTUgODQyXS9Sb3RhdGUgMC9SZXNvdXJjZXM8PC9Gb250PDwv');
        Base64Text.Append('aGVsdiA0IDAgUj4+Pj4vUGFyZW50IDIgMCBSL0NvbnRlbnRzIDYgMCBSPj4KZW5kb2JqCgo0IDAgb2JqCjw8L1R5cGUvRm9udC9TdWJ0eXBl');
        Base64Text.Append('L1R5cGUxL0Jhc2VGb250L0hlbHZldGljYS9FbmNvZGluZy9XaW5BbnNpRW5jb2Rpbmc+PgplbmRvYmoKCjUgMCBvYmoKPDwvVGl0bGUoSW52');
        Base64Text.Append('b2ljZSBJTlYtMjAwMikvQXV0aG9yKFRyeUFMIEZpeHR1cmUgR2VuZXJhdG9yKS9Qcm9kdWNlcihUcnlBTCkvQ3JlYXRvcihUcnlBTCk+Pgpl');
        Base64Text.Append('bmRvYmoKCjYgMCBvYmoKPDwvTGVuZ3RoIDE3OC9GaWx0ZXIvRmxhdGVEZWNvZGU+PgpzdHJlYW0KeJyNzk0LgkAQxvGv8hzzYM1u+dI16MUO');
        Base64Text.Append('UbF1yQ6bbiTorq5a9O0Tg44hcxkG/j+mwkJMHip/gjGIOxioG4aAI/A4RHEZ7YxNX5lOsZdlpizWxW3jXMUWS4EDqj/AdNYDkX6aLFGIdmeX');
        Base64Text.Append('E/FhMfO/cV23KgUnrNTNttK+u517gwx/HvaGMI3MsTwd4RGNiYbFIfVxPKoTqXX3Q2LKN1xog7qxbdK0tjumspGx8xM/h4taaQplbmRzdHJl');
        Base64Text.Append('YW0KZW5kb2JqCgp4cmVmCjAgNwowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwNDIgMDAwMDAgbiAKMDAwMDAwMDEyMCAwMDAwMCBuIAow');
        Base64Text.Append('MDAwMDAwMTcyIDAwMDAwIG4gCjAwMDAwMDAyOTYgMDAwMDAgbiAKMDAwMDAwMDM4NSAwMDAwMCBuIAowMDAwMDAwNDkzIDAwMDAwIG4gCgp0');
        Base64Text.Append('cmFpbGVyCjw8L1NpemUgNy9JbmZvIDUgMCBSL1Jvb3QgMSAwIFIvSURbPDEyQzJCOUMyODcxMkMzQjkwQzZGMDM3MEMyQjg0MzY2Pjw3RTRG');
        Base64Text.Append('NUJDNkNGQTY3NTFFRDcyOUYwNEUyOEQ2RTRDOD5dPj4Kc3RhcnR4cmVmCjc0MAolJUVPRgo=');
    end;
}
