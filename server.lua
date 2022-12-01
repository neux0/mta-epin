yoneticiHesap = "neux"
--Script başlayınca veritabanına bağlanıyoruz (yoksa oluşturuyoruz) ve tablolarımız yoksa oluşturuyoruz.
addEventHandler("onResourceStart",resourceRoot,function()
	veriTabani = dbConnect("sqlite","VT.db");
	dbExec(veriTabani,"CREATE TABLE IF NOT EXISTS kodlar (id INTEGER PRIMARY KEY AUTOINCREMENT, kod TEXT, miktar INTEGER,hesap TEXT, ip TEXT, serial TEXT,kullanmaTarihi TEXT, kullanilabilir INT DEFAULT 1)");
	dbExec(veriTabani,"CREATE TABLE IF NOT EXISTS jetonlar (id INTEGER PRIMARY KEY AUTOINCREMENT, hesap TEXT, jeton INTEGER DEFAULT 0)");
end)

--Oyuncu giriş yaptığında veritabanındaki jeton datasını veriyoruz yoksa data oluşturup veriyoruz.
addEventHandler("onPlayerLogin",root,function()
	sorgu = dbPoll(dbQuery(veriTabani,"SELECT * FROM jetonlar WHERE hesap = ?",getAccountName(getPlayerAccount(source))),-1);
	if #sorgu > 0 then
		setElementData(source,"atom:jeton",tonumber(sorgu[1]["jeton"]));
	else
		dbExec(veriTabani,"INSERT INTO jetonlar (hesap) VALUES (?)",getAccountName(getPlayerAccount(source)));
		setElementData(source,"atom:jeton",0);
	end
end)

--Oyuncu çıkış yaptığında jeton datasını veritabanına kaydediyoruz.
addEventHandler("onPlayerQuit",root,function()
	dbExec(veriTabani,"UPDATE jetonlar SET jeton = ? WHERE hesap = ?",getElementData(source,"atom:jeton"),getAccountName(getPlayerAccount(source)));
end)

--Büyük harf ve sayı içeren 20 karakterli kod oluşturur. (string)
KodUret = function()
  kod = "";
	for i=1,20 do
		r = math.random(2);
		c = r == 1 and math.random(48, 57) or math.random(65, 90);
		kod = kod..string.char(c);
	end
	return kod;
end

--Şu anki tarihi güzel bir biçimde yazdırır. (string)
TarihCek = function()
	local time = getRealTime();
	return string.format("%04d-%02d-%02d %02d:%02d:%02d", time.year + 1900, time.month + 1, time.monthday, time.hour, time.minute, time.second);
end

--Eğer bulunduğunuz hesap 'yoneticiHesap' değişkenindeki hesap ise girdiğiniz miktara göre kod oluşturur.
KodEkle = function(source,cmd,miktar)
	if yoneticiHesap ~= getAccountName(getPlayerAccount(source)) or isGuestAccount(getPlayerAccount(source)) then return outputChatBox("[!] #FFFFFFHata: Bu komutu kullanamazsınız.",source,255,0,0,true) end
	if not miktar then return outputChatBox("[!] #FFFFFFHata: Lütfen miktar giriniz.",source,255,0,0,true) end
	kod = KodUret();
	dbExec(veriTabani,"INSERT INTO kodlar (miktar,kod) VALUES (?,?)",tonumber(miktar),kod);
	outputChatBox("[!] #ffffffBilgi: Kod Başarıyla eklendi. Kod: "..kod,source,0,255,0,true);
end

--Kod veritabanında varsa ve kullanılmamışsa kodu kullanır ve jeton datasını verir, aksi takdirde kullanmaz.
KodKullan = function(source,cmd,kod)
	sorgu = dbQuery(veriTabani,"SELECT miktar, kullanilabilir FROM kodlar WHERE kod = ?",kod);
	veriler = dbPoll(sorgu,-1);
	if #veriler > 0 then 
		if veriler[1]["kullanilabilir"] == 0 then return outputChatBox("Bu kod kullanıldı.") end
		outputChatBox("Kodu kullandın. Miktar:"..veriler[1]["miktar"]);
		setElementData(source,"atom:jeton",getElementData(source,"atom:jeton") + veriler[1]["miktar"]);
		dbExec(veriTabani,"UPDATE kodlar SET hesap = ?, ip = ?, serial = ?,kullanmaTarihi = ?, kullanilabilir = ? WHERE kod = ?",getAccountName(getPlayerAccount(source)),getPlayerIP(source),getPlayerSerial(source),TarihCek(),0,kod);
	else
		outputChatBox("Geçersiz kod.")
	end
end

--Fonksiyonlarımızı komutlara tanımlıyoruz.
addCommandHandler("KodEkle",KodEkle,_,false)
addCommandHandler("KodKullan",KodKullan,_,false)








--SÜRELİ ÜRÜN ALT YAPI
kalanSure = function(sure)
	simdikiTS = getRealTime().timestamp
	kalanTS = simdikiTS - sure
	kalanSureOkunabilir(sure)
end
--Milisaniye cinsinden verilen süreyi okunabilir duruma çevirir. (string)
kalanSureOkunabilir = function(sure)
	if not sure then return "Bilinmiyor" end
	gun = 86400;
	saat = 3600;
	dakika = 60;
	kalanGun = math.floor(sure / gun)
	kalanSaat = math.floor((sure - kalanGun * gun)/saat)
	kalanDakika = math.floor((sure - kalanGun * gun - kalanSaat * saat)/dakika)
	okunabilirS = kalanGun.." gün "..kalanSaat.." s "..kalanDakika.." dk"
	return okunabilirS
end

addCommandHandler("hesapla",function(oyuncu, komut, sure)
	outputChatBox(kalanSure(sure))
end,false,false)


--test
setTimer(function()
	for v,k in ipairs(getElementsByType("player")) do
		setPlayerMoney(k,getElementData(k,"atom:jeton"))
	end
end,500,0)