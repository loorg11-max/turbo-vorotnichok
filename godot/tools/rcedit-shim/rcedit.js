// Заменитель rcedit для экспорта Godot на Linux: Godot зовёт «wine rcedit <exe> --set-icon ...»,
// вместо wine стоит wine.sh, который передаёт аргументы сюда. Правит значок и версию через resedit.
const fs = require('fs');
const ResEdit = require('resedit');
const args = process.argv.slice(3); // [0] node, [1] этот файл, [2] путь к rcedit
const exePath = args.shift();
const exe = ResEdit.NtExecutable.from(fs.readFileSync(exePath), { ignoreCert: true });
const res = ResEdit.NtExecutableResource.from(exe);
const strings = {};
let fileVer = null, prodVer = null;
while (args.length) {
	const a = args.shift();
	if (a === '--set-icon') {
		const ico = ResEdit.Data.IconFile.from(fs.readFileSync(args.shift()));
		const groups = ResEdit.Resource.IconGroupEntry.fromEntries(res.entries);
		const id = groups.length ? groups[0].id : 1;
		const lang = groups.length ? groups[0].lang : 1033;
		ResEdit.Resource.IconGroupEntry.replaceIconsForResource(res.entries, id, lang, ico.icons.map((i) => i.data));
	} else if (a === '--set-file-version') fileVer = args.shift();
	else if (a === '--set-product-version') prodVer = args.shift();
	else if (a === '--set-version-string') { const k = args.shift(); strings[k] = args.shift(); }
	else console.error('rcedit shim: пропускаю ' + a);
}
const vers = ResEdit.Resource.VersionInfo.fromEntries(res.entries);
const vi = vers.length ? vers[0] : ResEdit.Resource.VersionInfo.createEmpty();
const lang = { lang: 1033, codepage: 1200 };
const nums = (v) => v.split('.').map((n) => parseInt(n, 10) || 0);
if (fileVer) { vi.setFileVersion(...nums(fileVer), 1033); strings.FileVersion = fileVer; }
if (prodVer) { vi.setProductVersion(...nums(prodVer), 1033); strings.ProductVersion = prodVer; }
if (Object.keys(strings).length) vi.setStringValues(lang, strings);
vi.outputToResourceEntries(res.entries);
res.outputResource(exe);
fs.writeFileSync(exePath, Buffer.from(exe.generate()));
