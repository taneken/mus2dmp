# mus2dmp
X68000 mus fileから音色データを取り出し、DefleMaskのdmpファイルを生成するスクリプト

## 使い方
usage: mus2dmp_deflemask_YM2151.pl [filename.mus]

出力: filename_nnn.dmp 音色データの数分ファイルが生成されます。

## 補足
musファイルの拡張子は小文字で「.mus」付きを判定しています。それ以外は正しく動作しません。

MDXファイルからmusファイルの変換に、tmdx2musを使用しています。それ以外では試してません。
