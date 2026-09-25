from pathlib import Path
import csv, random, json, hashlib, zipfile
from datetime import date, timedelta
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP

ROOT=Path(__file__).resolve().parents[1]
for p in ['data','docs','sql','powerbi','screenshots','scripts']: (ROOT/p).mkdir(parents=True,exist_ok=True)
r=random.Random(20260913)
START=date(2024,1,1); END=date(2025,12,31)
def money(x): return float(Decimal(str(x)).quantize(Decimal('.01'),rounding=ROUND_HALF_UP))
def ds(x): return x.isoformat() if x else ''
tables={}; descriptions={}; grains={}
def table(name, grain, fields):
    grains[name]=grain; descriptions[name]=dict(fields); tables[name]=[]
def add(name, **kw):
    assert list(kw)==list(descriptions[name]), (name,list(kw))
    tables[name].append(kw)
table('Customers','One retail outlet / customer account; CustomerID is the primary key.',[
 ('CustomerID','int; primary key'),('CustomerName','varchar(80); fictional outlet name'),('Region','varchar(20); geographic sales region'),('Channel','varchar(30); raw ERP channel label; trim and standardize case'),('CustomerSegment','varchar(20); outlet size'),('OnboardDate','date; account activation'),('CreditLimitGBP','decimal(18,2); approved credit, not receivables'),('PaymentTermsDays','int; contractual credit days'),('SalesRepCode','varchar(20); blank means unassigned')])
table('SalesOrderLines','One order line; OrderLineID is primary key; OrderID has 1-3 lines.',[
 ('OrderLineID','int; primary key'),('OrderID','varchar(20); order identifier'),('LineNumber','int; unique within order'),('OrderDate','date; order cohort date'),('PromisedDate','date; requested complete arrival'),('CustomerID','int; FK Customers'),('ProductID','varchar(12); finished-goods SKU'),('ProductName','varchar(80); stable SKU description'),('Category','varchar(30); product category'),('Brand','varchar(30); fictional brand'),('UnitsPerCase','int; eaches in one case'),('WarehouseID','varchar(12); ship-from co-located factory warehouse'),('OrderedCases','int; gross demand before cancellation'),('CancelledCases','int; cancelled demand, not service failure'),('ListPricePerCaseGBP','decimal(18,2); ex VAT price'),('DiscountRate','decimal(9,4); fraction, not percent points'),('PromoCode','varchar(20); blank means no promotion'),('OrderStatus','varchar(20); Cancelled, Open, InTransit, Closed or ClosedShort')])
table('DeliveryLines','One dispatch allocation against an order line; split dispatch records are possible.',[
 ('DeliveryLineID','int; primary key'),('OrderLineID','int; FK SalesOrderLines'),('DispatchDate','date; stock issue and invoice recognition date'),('DeliveredDate','date nullable; blank means in transit at cutoff'),('ShippedCases','int; dispatched quantity'),('NetUnitPriceGBP','decimal(18,2); discounted invoice price per case'),('NetInvoiceGBP','decimal(18,2); shipped cases times net unit price'),('StandardCostPerCaseGBP','decimal(18,2); frozen dispatch-date standard cost'),('COGSGBP','decimal(18,2); shipped cases times standard cost'),('FreightGBP','decimal(18,2); shipment freight expense'),('CarrierCode','varchar(20); carrier identifier'),('DeliveryStatus','varchar(20); Delivered or InTransit')])
table('ReturnLines','One return credit against a delivery line; at most one in this simulation.',[
 ('ReturnLineID','int; primary key'),('DeliveryLineID','int; FK DeliveryLines'),('ReturnDate','date; goods received and credit posted'),('ReturnedCases','int; not more than delivered cases'),('ReasonCode','varchar(30); return cause'),('CreditAmountGBP','decimal(18,2); quantity times original net invoice unit price'),('HandlingCostGBP','decimal(18,2); incremental return handling expense'),('Disposition','varchar(20); Destroyed; zero recovery value')])
table('ProductionBatches','One completed finished-goods production batch; no open work in progress.',[
 ('BatchID','int; primary key'),('ProductionDate','date; completion and warehouse receipt date'),('ProductID','varchar(12); shared SKU key'),('PlantID','varchar(12); manufacturing site'),('WarehouseID','varchar(12); destination co-located warehouse'),('LineCode','varchar(20); plant-local line'),('PlannedCases','int; target batch quantity'),('ProducedCases','int; good plus rejected output'),('GoodCases','int; saleable quantity received'),('RejectedCases','int; production scrap'),('ScheduledMinutes','int; scheduled batch slot'),('DowntimeMinutes','int; within scheduled slot'),('DowntimeReason','varchar(30); dominant downtime reason'),('StandardCostPerCaseGBP','decimal(18,2); same cost schedule as dispatch'),('ActualConversionCostGBP','decimal(18,2); labour and overhead only, excludes materials')])
table('InventoryDaily','One end-of-day date x warehouse x SKU snapshot; SnapshotID is primary key.',[
 ('SnapshotID','int; primary key'),('SnapshotDate','date; end of day'),('WarehouseID','varchar(12); shared location key'),('ProductID','varchar(12); shared SKU key'),('OpeningCases','int; previous day closing, except seeded opening'),('ProductionReceiptCases','int; good production received'),('ShippedCases','int; dispatch quantity; not arrival quantity'),('WriteOffCases','int; damaged warehouse stock removed'),('ClosingCases','int; opening + receipts - shipped - writeoffs'),('StandardCostPerCaseGBP','decimal(18,2); end-of-day standard cost'),('ClosingValueGBP','decimal(18,2); closing cases times standard cost'),('SafetyStockCases','int; operating policy threshold')])
table('ProcurementReceipts','One fully received PO line; POReceiptID is primary key. Received-PO cohort only.',[
 ('POReceiptID','int; primary key'),('PONumber','varchar(20); one line per PO in simulation'),('SupplierID','varchar(12); shared supplier code'),('SupplierName','varchar(80); fictional supplier'),('MaterialID','varchar(12); raw material or packaging, not finished-goods SKU'),('MaterialName','varchar(80); material description'),('MaterialUOM','varchar(12); KG or PCS; never sum across UOM'),('PlantID','varchar(12); receiving site'),('PODate','date; purchase order date'),('PromisedReceiptDate','date; due date'),('ActualReceiptDate','date; actual receipt'),('OrderedQty','int; fully received gross quantity'),('ReceivedQty','int; includes rejected quantity'),('RejectedQty','int; supplier quality rejects'),('ContractUnitPriceGBP','decimal(18,2); agreed material rate'),('ActualUnitPriceGBP','decimal(18,2); invoiced material rate'),('InvoiceAmountGBP','decimal(18,2); gross receipt times actual price; no supplier credits modeled')])
regions=['North','South','East','West']; cats=['Beverages','Snacks','Personal Care','Home Care','Packaged Foods']
products={f'SKU{i:03}':{'name':f'{cats[(i-1)//12]} Variant {(i-1)%12+1:02}','cat':cats[(i-1)//12],'brand':['Vale','Crispa','Purely','BrightNest','PantryCo'][(i-1)//12],'units':[12,24,6][i%3],'price':money(16+(i%12)*2.3+((i-1)//12)*4)} for i in range(1,61)}
def cost(sku,d):
    p=products[sku]; inflation=1.14 if d>=date(2025,4,1) and p['cat'] in ['Snacks','Packaged Foods'] else 1.025 if d.year==2025 else 1
    return money(p['price']*.62*inflation)
for i in range(1,12001):
    channel=r.choices(['Traditional Trade','Modern Trade','Wholesale','Ecommerce'],[55,20,18,7])[0]
    if i%97==0: channel=' '+channel.upper()+' '
    add('Customers',CustomerID=i,CustomerName=f'Fictional Outlet {i:05}',Region=regions[(i-1)%4],Channel=channel,CustomerSegment=r.choice(['Small','Medium','Large']),OnboardDate=ds(date(2022,1,1)+timedelta(days=r.randrange(730))),CreditLimitGBP=r.choice([5000,10000,25000,50000]),PaymentTermsDays=r.choice([15,30,45,60]),SalesRepCode='' if i%113==0 else f'REP{i%80+1:03}')
pending=defaultdict(list); order_map={}; stock={(w,s):300 for w in range(1,5) for s in products}; did=0; oid=0
for di in range((END-START).days+1):
    d=START+timedelta(days=di); receipts=defaultdict(int); issues=defaultdict(int); openings=stock.copy()
    for (w,s),qty in stock.items():
        if (di+int(s[-3:])+w)%3==0:
            trouble=w==3 and date(2025,6,1)<=d<=date(2025,8,31)
            down=r.randint(25,55) if trouble else r.randint(0,18)
            planned=r.randint(200,260); produced=int(planned*(120-down)/120*r.uniform(.94,1.02)); reject=int(produced*r.uniform(.015,.085 if trouble else .04)); good=produced-reject
            add('ProductionBatches',BatchID=len(tables['ProductionBatches'])+1,ProductionDate=ds(d),ProductID=s,PlantID=f'PL{w:02}',WarehouseID=f'WH{w:02}',LineCode=f'L{int(s[-3:])%4+1}',PlannedCases=planned,ProducedCases=produced,GoodCases=good,RejectedCases=reject,ScheduledMinutes=120,DowntimeMinutes=down,DowntimeReason='Mechanical' if trouble else ('None' if down==0 else r.choice(['Changeover','Cleaning','Mechanical','Material Wait'])),StandardCostPerCaseGBP=cost(s,d),ActualConversionCostGBP=money(produced*r.uniform(1.8,2.6)+(90 if trouble else 0)))
            stock[w,s]+=good; receipts[w,s]+=good
    # 100 orders/day with 1-3 lines; shared customer and promise per order.
    for j in range(100):
        oid+=1; customer=(oid-1)%12000+1 if oid<=12000 else r.randint(1,12000); w=(customer-1)%4+1
        for ln,s in enumerate(r.sample(list(products),r.randint(1,3)),1):
            p=products[s]; promo=(d.month in [6,7,11] and int(s[-3:])%3==0 and r.random()<.65); qty=r.randint(24,110)
            if p['cat']=='Beverages' and d.month in [6,7,8]: qty=int(qty*1.4)
            if promo: qty=int(qty*1.25)
            if d.year==2025: qty=int(qty*1.08)
            cancel=qty if r.random()<.02 else 0; n=len(tables['SalesOrderLines'])+1
            add('SalesOrderLines',OrderLineID=n,OrderID=f'SO{oid:07}',LineNumber=ln,OrderDate=ds(d),PromisedDate=ds(d+timedelta(days=4)),CustomerID=customer,ProductID=s,ProductName=p['name'],Category=p['cat'],Brand=p['brand'],UnitsPerCase=p['units'],WarehouseID=f'WH{w:02}',OrderedCases=qty,CancelledCases=cancel,ListPricePerCaseGBP=money(p['price']*(1.04 if d.year==2025 else 1)),DiscountRate=.18 if promo else r.choice([0,.03,.05,.08]),PromoCode=f'PROMO{d.year}{d.month:02}' if promo else '',OrderStatus='Cancelled' if cancel else 'Open')
            order_map[n]=tables['SalesOrderLines'][-1]
            if not cancel: pending[d+timedelta(days=r.randint(1,3))].append(n)
    for n in pending.pop(d,[]):
        o=order_map[n]; w=int(o['WarehouseID'][-2:]); s=o['ProductID']; available=min(stock[w,s],o['OrderedCases']); stock[w,s]-=available; issues[w,s]+=available
        splits=[available]
        if available>=4 and r.random()<.18: splits=[available//2,available-available//2]
        arrivals=[]
        for qty in splits:
            if not qty: continue
            did+=1; carrier=r.choice(['CAR01','CAR02','CAR03']); delay=r.randint(3,6) if carrier=='CAR03' and w==3 and d.year==2025 else r.randint(1,3); arrival=d+timedelta(days=delay); arrivals.append(arrival)
            price=money(o['ListPricePerCaseGBP']*(1-o['DiscountRate']))
            add('DeliveryLines',DeliveryLineID=did,OrderLineID=n,DispatchDate=ds(d),DeliveredDate=ds(arrival) if arrival<=END else '',ShippedCases=qty,NetUnitPriceGBP=price,NetInvoiceGBP=money(qty*price),StandardCostPerCaseGBP=cost(s,d),COGSGBP=money(qty*cost(s,d)),FreightGBP=money(7+qty*(.35 if carrier=='CAR01' else .5)),CarrierCode=carrier,DeliveryStatus='Delivered' if arrival<=END else 'InTransit')
        o['OrderStatus']='InTransit' if any(a>END for a in arrivals) else ('Closed' if available==o['OrderedCases'] else 'ClosedShort')
    for (w,s),qty in stock.items():
        write=min(qty,int(qty*r.uniform(.001,.004))) if r.random()<.06 else 0; stock[w,s]-=write
        add('InventoryDaily',SnapshotID=len(tables['InventoryDaily'])+1,SnapshotDate=ds(d),WarehouseID=f'WH{w:02}',ProductID=s,OpeningCases=openings[w,s],ProductionReceiptCases=receipts[w,s],ShippedCases=issues[w,s],WriteOffCases=write,ClosingCases=stock[w,s],StandardCostPerCaseGBP=cost(s,d),ClosingValueGBP=money(stock[w,s]*cost(s,d)),SafetyStockCases=180)
    for k in range(24):
        n=len(tables['ProcurementReceipts'])+1; material=r.randint(1,20); supplier=r.randint(1,24); w=r.randint(1,4); bad=supplier in [7,19] and d.year==2025
        due=d-timedelta(days=r.randint(3,10) if bad else r.randint(-2,3)); pod=min(d,due)-timedelta(days=r.randint(7,21)); qty=r.randint(500,8000); contract=money(.15+material*.12); actual=money(contract*(1.18 if material<=10 and d>=date(2025,4,1) else r.uniform(.97,1.04)))
        add('ProcurementReceipts',POReceiptID=n,PONumber=f'PO{n:07}',SupplierID=f'SUP{supplier:03}',SupplierName=f'Fictional Supplier {supplier:02}',MaterialID=f'MAT{material:03}',MaterialName=f'{"Ingredient" if material<=10 else "Packaging"} {material:02}',MaterialUOM='KG' if material<=10 else 'PCS',PlantID=f'PL{w:02}',PODate=ds(pod),PromisedReceiptDate=ds(due),ActualReceiptDate=ds(d),OrderedQty=qty,ReceivedQty=qty,RejectedQty=int(qty*r.uniform(.04,.10) if bad else qty*r.uniform(0,.025)),ContractUnitPriceGBP=contract,ActualUnitPriceGBP=actual,InvoiceAmountGBP=money(qty*actual))
for delivery in tables['DeliveryLines']:
    if not delivery['DeliveredDate']: continue
    o=order_map[delivery['OrderLineID']]; high=o['Category']=='Beverages' and o['WarehouseID']=='WH03' and o['OrderDate'].startswith('2025-0')
    if r.random()>(.23 if high else .12): continue
    rd=date.fromisoformat(delivery['DeliveredDate'])+timedelta(days=r.randint(4,28))
    if rd>END: continue
    qty=max(1,int(delivery['ShippedCases']*r.uniform(.02,.12)))
    add('ReturnLines',ReturnLineID=len(tables['ReturnLines'])+1,DeliveryLineID=delivery['DeliveryLineID'],ReturnDate=ds(rd),ReturnedCases=qty,ReasonCode='Damaged' if high else r.choice(['Damaged','Quality','Short Shelf Life','Customer Rejection']),CreditAmountGBP=money(qty*delivery['NetUnitPriceGBP']),HandlingCostGBP=money(2+qty*.45),Disposition='Destroyed')

# Structural and cross-table validations before delivering source extracts.
checks=[]
def check(label,condition):
    assert condition,label
    checks.append({'check':label,'result':'PASS'})
for name,rows in tables.items():
    pk=next(iter(descriptions[name])); check(name+' >10000 rows',len(rows)>10000); check(name+' unique non-null primary key',len({x[pk] for x in rows})==len(rows) and all(x[pk] for x in rows))
check('Order and line number unique',len({(x['OrderID'],x['LineNumber']) for x in tables['SalesOrderLines']})==len(order_map))
check('Sales customer foreign keys valid',all(1<=x['CustomerID']<=12000 for x in order_map.values()))
deliveries={x['DeliveryLineID']:x for x in tables['DeliveryLines']}; shipped=defaultdict(int); received=defaultdict(int); invship=defaultdict(int)
for x in deliveries.values():
    o=order_map[x['OrderLineID']]; shipped[x['OrderLineID']]+=x['ShippedCases']; invship[x['DispatchDate'],o['WarehouseID'],o['ProductID']]+=x['ShippedCases']
    assert x['DispatchDate']>=o['OrderDate'] and (not x['DeliveredDate'] or x['DeliveredDate']>=x['DispatchDate'])
    assert x['NetInvoiceGBP']==money(x['ShippedCases']*x['NetUnitPriceGBP']) and x['COGSGBP']==money(x['ShippedCases']*x['StandardCostPerCaseGBP'])
check('Delivery dates, foreign keys and invoice arithmetic valid',True)
check('No overshipment',all(shipped[n]<=o['OrderedCases']-o['CancelledCases'] for n,o in order_map.items()))
for x in tables['ProductionBatches']:
    assert x['GoodCases']+x['RejectedCases']==x['ProducedCases'] and 0<=x['DowntimeMinutes']<=x['ScheduledMinutes']
    received[x['ProductionDate'],x['WarehouseID'],x['ProductID']]+=x['GoodCases']
prior={}
for x in tables['InventoryDaily']:
    key=x['SnapshotDate'],x['WarehouseID'],x['ProductID']; pair=key[1:]
    assert x['OpeningCases']==prior.get(pair,300)
    assert x['ProductionReceiptCases']==received[key] and x['ShippedCases']==invship[key]
    assert x['ClosingCases']==x['OpeningCases']+x['ProductionReceiptCases']-x['ShippedCases']-x['WriteOffCases'] and x['ClosingCases']>=0
    assert x['ClosingValueGBP']==money(x['ClosingCases']*x['StandardCostPerCaseGBP'])
    prior[pair]=x['ClosingCases']
check('Daily inventory continuity, production receipts, dispatch issues and values reconcile',True)
returned=defaultdict(int)
for x in tables['ReturnLines']:
    d=deliveries[x['DeliveryLineID']]; returned[x['DeliveryLineID']]+=x['ReturnedCases']
    assert d['DeliveredDate'] and x['ReturnDate']>=d['DeliveredDate'] and x['CreditAmountGBP']==money(x['ReturnedCases']*d['NetUnitPriceGBP'])
check('Return dates credits and quantities valid',all(q<=deliveries[n]['ShippedCases'] for n,q in returned.items()))
check('Procurement dates quantities invoices valid',all(x['PODate']<=x['ActualReceiptDate'] and x['PODate']<=x['PromisedReceiptDate'] and 0<=x['RejectedQty']<=x['ReceivedQty']==x['OrderedQty'] and x['InvoiceAmountGBP']==money(x['ReceivedQty']*x['ActualUnitPriceGBP']) for x in tables['ProcurementReceipts']))
manifest={}
for name,rows in tables.items():
    path=ROOT/'data'/f'{name}.csv'
    with path.open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=list(descriptions[name]),lineterminator='\n'); writer.writeheader(); writer.writerows(rows)
    with path.open(newline='',encoding='utf-8') as f: check(name+' CSV roundtrip row count',sum(1 for _ in csv.DictReader(f))==len(rows))
    manifest[name]={'rows':len(rows),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
dictionary=['# Data dictionary\n','All records are synthetic. UTF-8 comma-delimited CSV, header row, LF endings. Dates use YYYY-MM-DD. Empty CSV cells load as NULL in staging. All money is GBP excluding VAT. Quantity is cases unless specified. No thousands separators. SQL types below are suggested clean-layer types; initially stage raw columns as text.\n']
for name,fields in descriptions.items():
    dictionary += [f'## {name}\n',grains[name]+'\n',f'Rows: {len(tables[name]):,}\n','| Column | Meaning / suggested SQL type |\n|---|---|']+[f'| {k} | {v} |' for k,v in fields.items()]+['']
(ROOT/'docs'/'DATA_DICTIONARY.md').write_text('\n'.join(dictionary),encoding='utf-8')
(ROOT/'docs'/'DATA_MANIFEST.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
(ROOT/'docs'/'VALIDATION_REPORT.md').write_text('# Dataset validation\n\nValidated in Python before delivery; SQL Server import has not yet been run.\n\n'+'\n'.join('- '+x['check']+': '+x['result'] for x in checks)+'\n\nIntentional source-quality exercises: '+str(sum(x['Channel']!=x['Channel'].strip().title().replace('Ecommerce','Ecommerce') for x in tables['Customers']))+' channel labels may need case/space review; '+str(sum(not x['SalesRepCode'] for x in tables['Customers']))+' missing sales rep assignments. Missing promotion codes and in-transit arrival dates are valid NULLs. No duplicate keys or orphan foreign keys were deliberately inserted.\n',encoding='utf-8')
print(json.dumps(manifest,indent=2))

