public class CryptoClass {
    public static String  decrypt(String b64Data) {
        Blob blobData = EncodingUtil.base64Decode(b64Data);
        Blob decryptedData = Crypto.decryptWithManagedIV('AES128', Blob.valueOf(Label.Cryptokey) , blobData);
        String dryptData = decryptedData.toString();
        return dryptData;
    }
}