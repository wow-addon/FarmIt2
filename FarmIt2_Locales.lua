--------------------------------------------------------------------------------
--  LOCALIZATION STUFF
--
--  To do: Finish filling out all labels for each language.
--
--[[

Key: 
  [1] = "Item Level",
  [2] = "Stack Size",
  [3] = "Item ID",
  
  [4] = "Button ID",
  [5] = "Count",
  [6] = "Stacks",
  [7] = "Objective",
  [8] = "Include Bank",
  [9] = "Objective Complete",

]]--
--------------------------------------------------------------------------------

FI_LABELS = {};

local localization,language,labels;

localization = {
	--Chinese (simplified)
	["zhCN"] = {
		[1] = "物品等级",
		[2] = "堆叠大小",
		[3] = "物品编号",
		--
		[4] = "按钮识别号码",
		[5] = "总数",
		[6] = "栈",
		[7] = "目标",
		[8] = "包括银行",
		[9] = "目标完成",
	},
	
	--Chinese (traditional)
	["zhTW"] = {
		[1] = "物品等級",
		[2] = "堆疊大小",
		[3] = "物品編號",
		--
		[4] = "按鈕識別號碼",
		[5] = "總數",
		[6] = "棧",
		[7] = "目標",
		[8] = "包括銀行",
		[9] = "目標完成",
	},
	
	--English (United States and Great Britain)
	["enUS"] = {
		[1] = "Item Level",
		[2] = "Stack Size",
		[3] = "Item ID",
		--
		[4] = "Button ID",
		[5] = "Count",
		[6] = "Stacks",
		[7] = "Objective",
		[8] = "Include Bank",
		[9] = "Objective Complete",
	},
	
	--French
	["frFR"] = {
		[1] = "Qualité du Objet",
		[2] = "Grandeur du Tas",
		[3] = "Chiffre du Objet",
		--
		[4] = "Chiffre du Bouton",
		[5] = "Total",
		[6] = "Tas",
		[7] = "Objectif",
		[8] = "Compter Banque",
		[9] = "Objectif Terminé",
	},
	
	--German
	["deDE"] = {
		[1] = "Artikel Stufe",
		[2] = "Haufen Größe",
		[3] = "Artikel Anzahl",
		--
		[4] = "Taste Anzahl",
		[5] = "Zählen",
		[6] = "Stapel",
		[7] = "Ziel",
		[8] = "Enthalten Querlage",
		[9] = "Ziel Vollendet",
	},
	
	--Korean
	["koKR"] = {
		[1] = "항목의 품질",
		[2] = "걸어 총 크기",
		[3] = "한항 숫자",
		--
		[4] = "단추 숫자",
		[5] = "합계",
		[6] = "걸어 총",
		[7] = "목표",
		[8] = "포함하다 저장소",
		[9] = "포함하다 완전한",
	},
	
	--Russian (Requires UI AddOn)
	["ruRU"] = {
		[1] = "штука ступень",
		[2] = "куча величина",
		[3] = "штука цифра",
		--
		[4] = "кнопка цифра",
		[5] = "сумма",
		[6] = "куча",
		[7] = "цель",
		[8] = "включать хранилище",
		[9] = "цель законченный",
	},
	
	--Spanish (Spain)
	["esES"] = {
		[1] = "Calidad de Objeto",
		[2] = "Tamaño de Montón",
		[3] = "Número de Objeto",
		--
		[4] = "Número de Botón",
		[5] = "Cantidad",
		[6] = "Montón",
		[7] = "Objetivo",
		[8] = "Adjuntar Depósito",
		[9] = "Objetivo Completo",
	},
	
	--Spanish (Mexico)
	["esMX"] = {
		[1] = "Calidad de Objeto",
		[2] = "Tamaño de Montón",
		[3] = "Número de Objeto",
		--
		[4] = "Número de Botón",
		[5] = "Cantidad",
		[6] = "Montón",
		[7] = "Objetivo",
		[8] = "Adjuntar Depósito",
		[9] = "Objetivo Completo",
	},
}

-- get user pref
language = GetLocale();

-- load localized labels
labels = localization[language];

-- apply language choice
if (labels == nil) or (#labels < 3) then
	-- default to English
	labels = localization["enUS"];
end

-- set global constant
FI_LABELS = labels;
