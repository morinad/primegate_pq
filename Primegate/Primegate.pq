// This file contains your Data Connector logic
section Primegate;

[DataSource.Kind="Primegate", Publish="Primegate.Publish"]
shared Primegate.Data = Value.ReplaceType(Primegate.Func, FuncType);

FuncType = type function (
     tip  as (type text meta [        
        Documentation.FieldCaption = "Тип отчёта Primegate:",
         Documentation.SampleValues = {"lead"},
        Documentation.AllowedValues = { "lead", "contact", "deal" }
    ]),


site as (type text meta [
        Documentation.FieldCaption = "ID кабинета Primegate:",
        Documentation.SampleValues = {"1234"}
    ])


        )
    as table meta [
        Documentation.Name = "Получаем обращения, контакты или сделки из Primegate",
       Documentation.LongDescription = "URL для получения токена указан ниже.",
        Documentation.Examples = {
        [
            Description = "Получаем табличку с данными по звонкам Primegate",
            Code = "primegate(""lead"", ""4321"",""1hnjGH86gH-37BFL"")",
            Result = "Список строк с данными Primegate."
        ],
        [
            Description = "Получаем табличку с данными по целям Primegate",
            Code = "https://cloud.primegate.io/projects/settings/base",
            Result = "Токен кабинета Primegate."
        ]
        }
    ] ;

    
Primegate.Func =(tip as text, site as text)=>
let
step = 500,
reportType = if tip ="lead" then "lead/get" else
if tip = "contact" then "contact/get" else
if tip = "deal" then "deal/get" else "",
m= count(reportType,site,Extension.CurrentCredential()[Key],step),
countNumbers= m/step,
round = Number.RoundUp(countNumbers),
getList= {0..round-1},
toTable = Table.FromList(getList, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
result = if round = 0 then toTable else
let 
changeType = try Table.TransformColumnTypes(toTable,{{"Column1", Int64.Type}}) otherwise toTable ,
multiple = try Table.TransformColumns(changeType, {{"Column1", each _ * step, type number}}) otherwise changeType ,
getData= try Table.AddColumn(multiple, "Пользовательский", each data(reportType, site, Extension.CurrentCredential()[Key], [Column1], step)) otherwise multiple ,
expand = try Table.ExpandTableColumn(getData, "Пользовательский", {"Column1"}, {"Column2"}) otherwise getData,
hours = Number.From(Text.BeforeDelimiter(Text.AfterDelimiter(Text.From(DateTimeZone.LocalNow()),"+"),":")),
transform = Table.RemoveColumns(Table.AddColumn(expand , "data", each 
try Record.TransformFields([Column2], {{"created_at", each #datetime(1970,1,1,hours,0,0)+ #duration(0,0,0,_)}, {"updated_at", each #datetime(1970,1,1,hours,0,0)+ #duration(0,0,0,_)}}) otherwise 
Record.TransformFields([Column2], {{"create_at", each #datetime(1970,1,1,hours,0,0)+ #duration(0,0,0,_)}, {"update_at", each #datetime(1970,1,1,hours,0,0)+ #duration(0,0,0,_)}}) 
),{"Column1", "Column2"}) 
in 
transform

in
   result;


count = (rType as text, site as text, token as text, step as number)=>
let
data = Json.FromValue([limit=step , offset=0]),
get = [#"site_id"=site, #"key"=token],
web = try Json.Document(Web.Contents("https://api.primegate.io/v2/", [Query=get, RelativePath = rType , Content=data, ManualStatusHandling={404, 400}]))[data][count] otherwise 0
in web;


data=(rType as text, site as text, token as text, off as number, step as number)=>
let
data = Json.FromValue([limit=step, offset=off]),
get = [#"site_id"=site, #"key"=token],
web = Json.Document(Web.Contents("https://api.primegate.io/v2/", [Query=get, RelativePath = rType, Content=data, ManualStatusHandling={404, 400}])),
    data1 = web[data],
    rows = data1[rows],
    #"Преобразовано в таблицу" = Table.FromList(rows, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
in
    #"Преобразовано в таблицу";




Primegate = [
    TestConnection = (dataSourcePath) => 
        { "Primegate.Data", 
        Json.Document(dataSourcePath)[tip], 
        Json.Document(dataSourcePath)[site]},
    Authentication = [
        
         Key = []
   
    ],
    Label = "Primegate Connection"
];



Primegate.Publish = [
    Beta = false,
    Category = "Other",
    ButtonText = { "Primegate Connector", "Primegate Help" },
    LearnMoreUrl = "https://www.youtube.com/channel/UCqSLNYLN_3mf6nA1Xf7fu1g/",
    SourceImage = Primegate.Icons,
    SourceTypeImage = Primegate.Icons
];



Primegate.Icons = [
    Icon16 = { Extension.Contents("Primegate16.png"), Extension.Contents("Primegate20.png"), Extension.Contents("Primegate24.png"), Extension.Contents("Primegate32.png") },
    Icon32 = { Extension.Contents("Primegate32.png"), Extension.Contents("Primegate40.png"), Extension.Contents("Primegate48.png"), Extension.Contents("Primegate64.png") }
];
