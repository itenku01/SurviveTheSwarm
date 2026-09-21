# 🧟 Survive The Swarm [ZOMBIES] - Mobile Hub

> **สุดยอดสคริปต์ช่วยเล่นสำหรับ Survive The Swarm [ZOMBIES] บน Roblox**  
> ออกแบบมาเป็นพิเศษสำหรับหน้าจอมือถือและการควบคุมด้วยระบบสัมผัส พร้อมฟีเจอร์ระดับพรีเมียมและระบบกันหลุดข้ามห้องอัตโนมัติ 100%

---

## ⚡ วิธีรันสคริปต์ (Quick Start)

คัดลอกโค้ด **1 บรรทัด** ด้านล่างนี้ไปวางใน Executor ของคุณ (เช่น Delta, Codex, Fluxus, Arceus X, MuMu Player, KRNL ฯลฯ) แล้วกด Execute:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/itenku01/SurviveTheSwarm/main/loader.luau"))()
```

*(หรือหาก Executor ของคุณรองรับนามสกุล `.lua` สามารถใช้:)*
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/itenku01/SurviveTheSwarm/main/loader.lua"))()
```

---

## ✨ ไฮไลท์ฟีเจอร์เด่น (Key Features)

### 1. 🎴 ระบบเลือกการ์ดอัจฉริยะ (5-Tier Smart Card Engine)
- **เลือกอาวุธ & สกิล Passive ได้หลายชิ้นพร้อมกัน:** หน้าต่าง POPUP เลือกลิสต์การ์ดที่ต้องการล่วงหน้า หากชิ้นแรกไม่สุ่มมา ระบบจะเลือกชิ้นถัดไปให้โดยอัตโนมัติ
- **ค้นหาเรียลไทม์ (Search Bar):** พิมพ์ค้นหาการ์ดที่ต้องการได้ทันที พร้อมปุ่มเคลียร์ `X` สะดวกรวดเร็ว
- **ไอคอนภาพการ์ดจริงจากระบบเกม:** ดึง Asset รูปภาพของอาวุธและพาสซีพมาแสดงผลบนปุ่มโดยตรง
- **ลำดับความสำคัญ 5 ระดับ:**
  1. การ์ดผสมขั้นสูง (Evolutions / Forge Combinations)
  2. อาวุธเป้าหมายที่เลือกไว้ในลิสต์ (Target Weapons)
  3. สกิล Passive เป้าหมายที่เลือกไว้ (Target Passives)
  4. อัปเกรดชิ้นที่มีอยู่เดิม (Upgrade Existing)
  5. ตัวเลือกสำรองที่ดีที่สุด (Fallback Pick)

### 2. 🛸 ระบบฟาร์มอัตโนมัติ (Safe Auto Farm)
- **Hover Farm:** ลอยตัวเหนือฝูงซอมบี้ที่ความสูงปลอดภัย ไม่โดนกัดตายง่ายๆ
- **Emergency Retreat:** ระบบถอยหนีฉุกเฉินอัตโนมัติเมื่อเลือดลดต่ำ พร้อมรักษาเกราะและฟื้นฟูพลังชีวิต
- **Safe Orb Collection:** ระบบวาร์ปลงมาดูดลูกแก้ว EXP และไอเทมดรอปเฉพาะช่วงที่ปลอดภัย
- **Bonus Waves Farm:** ฟาร์มเก็บรางวัลเวฟโบนัสจนถึงวินาทีสุดท้าย และกดออกจากฉากก่อนโดนหักคะแนน

### 3. ⏩ ระบบข้ามคัตซีน & สลับฉากอัตโนมัติ (QoL Automation)
- **Auto Skip Cutscene:** ตัดฉากกระสวยอวกาศตก (`PodArrival`) และฉากเปิดตัวบอส (`BossArrival`) ทันทีใน 0.05 วินาที
- **Auto Launch:** กดเริ่มเกมเมื่อพร้อมให้อัตโนมัติ
- **Match End Automation:** เลือกระบบจบเกมอัตโนมัติได้ (`เล่นอีกรอบทันที (Retry)` หรือ `กลับล็อบบี้ (Return to Lobby)`)
- **Teleport Persistence:** สคริปต์ไม่หลุดเมื่อย้ายจาก Lobby (`PlaceId: 100227226022278`) ไปยัง Match Arena (`PlaceId: 139536658319600`)

### 4. 📱 ออกแบบสำหรับมือถือ (Mobile-First Touch UI)
- **Floating Action Button (⚡ FAB):** ปุ่มไอคอนลอย พับเก็บและลากย้ายตำแหน่งบนหน้าจอได้อย่างอิสระ
- **ปุ่มปิด (X) & ปุ่มย่อ (-):** รองรับฟอนต์ Glyph ทุกโปรแกรมจำลองและมือถือ ไม่แสดงผลเป็นกล่องสี่เหลี่ยมว่าง
- **หน้า Config & Autoload โฉมใหม่:** มีการ์ดแดชบอร์ดบอกสถานะโปรไฟล์และสถานะโหลดอัตโนมัติชัดเจน
- **Auto-Scrolling Canvas:** หน้ารายการปุ่มและตัวช่วย (Utils) ปรับขนาดอัตโนมัติตามเนื้อหา เลื่อนดูได้ทุกปุ่มไม่ล้นจอ

---

## 🛠️ โครงสร้างไฟล์ในโปรเจกต์ (Repository Structure)

```text
├── loader.luau                # Universal GitHub Raw Loader พร้อมระบบ Teleport Persistence
├── loader.lua                 # Alias loader สำหรับโปรแกรมที่รองรับนามสกุล .lua
├── games/
│   └── survive_the_swarm.luau # ตัวโค้ดหลักเต็มรูปแบบ (Full Feature Script v1.4.0)
├── CHANGELOG.md               # ประวัติการอัปเดตและบันทึกการเปลี่ยนแปลงทั้งหมด
└── README.md                  # คู่มือการใช้งานและเอกสารประกอบ
```

---

## 📄 บันทึกการเปลี่ยนแปลง (Changelog)

ดูรายละเอียดการอัปเดตทุกเวอร์ชันได้ที่ [CHANGELOG.md](./CHANGELOG.md)

---

## ⚠️ ข้อสงวนสิทธิ์ (Disclaimer)
สคริปต์นี้พัฒนาขึ้นเพื่อการศึกษาและการทดสอบประสิทธิภาพการทำงานของระบบ Luau Scripting บน Roblox เท่านั้น ผู้พัฒนาไม่รับผิดชอบต่อการนำไปใช้งานที่ขัดต่อกฎของผู้ให้บริการเกม
