# LTIOUSB

CocoaでUSBドライバを作成するためのIOKitラッパー(ヘルパー)です。

特に面倒なデバイスの抜き差しのハンドリング、COM・プラグインインターフェース作成を楽にします。

逆に言えば、それ以外の実装、デバイス・インターフェースアクセスはデバイスごとに異なるため、それぞれのアプリケーションで実装します。


## LTIOUSBManager クラス

* シングルトン
* -startWithMatchingDictionaries
    * マッチング辞書で監視を開始します。すでに接続されているものがあれば、すぐに Notification が送信されます。マッチング辞書に関してはドキュメントや解説サイトを参照してください。
    
    ここで、マッチング辞書に LTIOUSBManagerObjectBaseClassKey を加えて、LTIOUSBDevice のサブクラスを設定すると、自動的にデバイス接続時にそのクラスがインスタンス化されます。下記参照。
* devices
    * マッチしたデバイスのリスト(過去に接続されていたものも含まれる場合がある。下記参照)



## LTIOUSBDevice クラス
抽象クラスです。通常はサブクラス化して使います。デバイスごと1つのインスタンスが作成されます。

* deviceInfo
    * デバイスの情報を取得。キーは USBSpec.h を参照してください。
* -createPluginInterface, -closePluginInterface
    * プラグインインターフェースを作成・破棄します。呼びすぎても問題ありません。
* -createDeviceInterface, -closeDeviceInterface
    * デバイスインターフェースを作成・破棄します。呼びすぎても問題ありません。
* -openDevice, -closeDevice, -resetDevice
    * デバイスインターフェースが作成されている必要があります。


### サブクラス化
* -deviceConnected, -deviceDisconnected
    * デバイスが接続・切断されたときに呼ばれます。
* +deviceIdentifier:
    * そのデバイスのユニークなID文字列を返します。
    * 一度接続されたデバイスが再接続されたとき、この文字列が同じであれば、再度同じインスタンスが使われます。
* +removeFromDeviceListOnDisconnect
    * デバイスが切断されたときに LTIOUSBManager クラスのデバイスリストから取り除くか設定します。

## その他
* ARCを使用しています。
* iOS環境でもコンパイルは可能ですが、iOS4以降はサンドボックスにより動作しません。Jailbreakが必要(未確認)。


## ライセンス
MITです。

Copyright © 2012 Yusuke Ito

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

