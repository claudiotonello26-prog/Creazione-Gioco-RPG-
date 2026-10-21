import os
import json

art_dir = r"C:\Users\pissio\.gemini\antigravity\brain\e03af584-5236-484d-a399-ef89e16e8081"
json_path = os.path.join(art_dir, "images", "b64_data.json")

with open(json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

html_content = f"""<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
  <style>
    .tab-btn.active {{
      background: #C9A24A;
      color: #0D0B09;
      font-weight: 600;
    }}
  </style>
</head>
<body class="bg-[#100E0D] text-[#E6D5B8] antialiased p-2 sm:p-4">
  <div class="max-w-4xl mx-auto bg-[#141210] border border-[#3A332B] rounded-2xl overflow-hidden shadow-2xl">
    
    <!-- Header -->
    <div class="bg-[#1C1815] border-b border-[#2D2620] p-4 flex flex-wrap items-center justify-between gap-3">
      <div>
        <h1 class="text-lg sm:text-xl font-bold text-[#E6D5B8] tracking-wide flex items-center gap-2">
          <span class="text-[#C9A24A]">⚔</span> GYM OATH — Anteprima Grafica HD
        </h1>
        <p class="text-xs text-[#A09383] mt-0.5">4 Mercanti (Sguardo Frontale & Amichevole) + 14 Nodi di Raccolta (512x512)</p>
      </div>
      <span class="px-2.5 py-1 text-[11px] font-semibold bg-[#222E1A] text-[#86EFAC] border border-[#2E4720] rounded-full">
        ✓ 18/18 pink_pixels = 0
      </span>
    </div>

    <!-- Navigation Tabs -->
    <div class="bg-[#110F0E] px-3 pt-3 flex gap-2 overflow-x-auto border-b border-[#25201B]">
      <button onclick="showTab('merchants')" id="tab-merchants" class="tab-btn active px-3.5 py-2 rounded-t-lg text-xs tracking-wider uppercase transition-colors text-[#A09383] hover:text-[#E6D5B8]">
        4 Mercanti (NPC)
      </button>
      <button onclick="showTab('checksheet')" id="tab-checksheet" class="tab-btn px-3.5 py-2 rounded-t-lg text-xs tracking-wider uppercase transition-colors text-[#A09383] hover:text-[#E6D5B8]">
        Master Sheet (18)
      </button>
      <button onclick="showTab('trees')" id="tab-trees" class="tab-btn px-3.5 py-2 rounded-t-lg text-xs tracking-wider uppercase transition-colors text-[#A09383] hover:text-[#E6D5B8]">
        Alberi (5)
      </button>
      <button onclick="showTab('ores')" id="tab-ores" class="tab-btn px-3.5 py-2 rounded-t-lg text-xs tracking-wider uppercase transition-colors text-[#A09383] hover:text-[#E6D5B8]">
        Minerali (9)
      </button>
    </div>

    <!-- Content Area -->
    <div class="p-4 sm:p-5">

      <!-- TAB 1: MERCHANTS -->
      <div id="content-merchants" class="space-y-4">
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
          
          <!-- Berta -->
          <div class="bg-[#191614] border border-[#2F2720] rounded-xl p-2.5 flex flex-col items-center text-center shadow">
            <div class="w-full aspect-square bg-[#0E0C0B] rounded-lg overflow-hidden flex items-center justify-center p-1">
              <img src="data:image/png;base64,{data['npc_individual']['general_store']}" class="w-full h-full object-contain filter drop-shadow-[0_4px_8px_rgba(0,0,0,0.6)]" alt="Berta">
            </div>
            <h3 class="text-sm font-semibold text-[#E6D5B8] mt-2">Berta</h3>
            <p class="text-[11px] text-[#C9A24A]">General Store</p>
            <p class="text-[10px] text-[#8C8072] mt-1 leading-tight">Viso pulito senza bug, sorriso caldo, occhiali ottone, sguardo in camera.</p>
          </div>

          <!-- Gorran -->
          <div class="bg-[#191614] border border-[#2F2720] rounded-xl p-2.5 flex flex-col items-center text-center shadow">
            <div class="w-full aspect-square bg-[#0E0C0B] rounded-lg overflow-hidden flex items-center justify-center p-1">
              <img src="data:image/png;base64,{data['npc_individual']['smith']}" class="w-full h-full object-contain filter drop-shadow-[0_4px_8px_rgba(0,0,0,0.6)]" alt="Mastro Gorran">
            </div>
            <h3 class="text-sm font-semibold text-[#E6D5B8] mt-2">Mastro Gorran</h3>
            <p class="text-[11px] text-[#C9A24A]">Fabbro</p>
            <p class="text-[10px] text-[#8C8072] mt-1 leading-tight">Tiene saldamente la tenaglia con la mano sulla spalla, sorriso in camera.</p>
          </div>

          <!-- Edda -->
          <div class="bg-[#191614] border border-[#2F2720] rounded-xl p-2.5 flex flex-col items-center text-center shadow">
            <div class="w-full aspect-square bg-[#0E0C0B] rounded-lg overflow-hidden flex items-center justify-center p-1">
              <img src="data:image/png;base64,{data['npc_individual']['hunter']}" class="w-full h-full object-contain filter drop-shadow-[0_4px_8px_rgba(0,0,0,0.6)]" alt="Edda">
            </div>
            <h3 class="text-sm font-semibold text-[#E6D5B8] mt-2">Edda</h3>
            <p class="text-[11px] text-[#C9A24A]">Cacciatrice</p>
            <p class="text-[10px] text-[#8C8072] mt-1 leading-tight">Sorriso sereno e accogliente, cappuccio e faretra, sguardo frontale.</p>
          </div>

          <!-- Velthar -->
          <div class="bg-[#191614] border border-[#2F2720] rounded-xl p-2.5 flex flex-col items-center text-center shadow">
            <div class="w-full aspect-square bg-[#0E0C0B] rounded-lg overflow-hidden flex items-center justify-center p-1">
              <img src="data:image/png;base64,{data['npc_individual']['mage']}" class="w-full h-full object-contain filter drop-shadow-[0_4px_8px_rgba(0,0,0,0.6)]" alt="Velthar">
            </div>
            <h3 class="text-sm font-semibold text-[#E6D5B8] mt-2">Velthar</h3>
            <p class="text-[11px] text-[#C9A24A]">Mago</p>
            <p class="text-[10px] text-[#8C8072] mt-1 leading-tight">Sguardo saggio e benevolo in camera, barba d'argento e bastone.</p>
          </div>

        </div>

        <div class="bg-[#1A1715] border border-[#2D2620] rounded-xl p-3">
          <h4 class="text-xs font-semibold text-[#C9A24A] uppercase tracking-wider mb-2">Confronto Schieramento Mercanti</h4>
          <img src="data:image/jpeg;base64,{data['merchants_banner']}" class="w-full rounded-lg shadow-md border border-[#29221D]" alt="Banner Mercanti">
        </div>
      </div>

      <!-- TAB 2: CHECK SHEET -->
      <div id="content-checksheet" class="hidden space-y-3">
        <div class="flex items-center justify-between">
          <p class="text-xs text-[#A09383]">Griglia completa 18 elementi su verde medio #00A859 (controllo aloni rosa):</p>
          <span class="text-[10px] text-[#86EFAC] bg-[#162916] px-2 py-0.5 rounded border border-[#2E4720]">Zero Pink Halos</span>
        </div>
        <div class="rounded-xl overflow-hidden border border-[#2D2620] shadow-xl bg-[#00A859]">
          <img src="data:image/jpeg;base64,{data['check']}" class="w-full h-auto object-contain" alt="Check Sheet Completo">
        </div>
      </div>

      <!-- TAB 3: TREES -->
      <div id="content-trees" class="hidden space-y-3">
        <p class="text-xs text-[#A09383]">5 Nodi di Taglialegna (Ash, Oak, Yew, Storm Pine, Ebony):</p>
        <div class="rounded-xl overflow-hidden border border-[#2D2620] shadow-xl">
          <img src="data:image/jpeg;base64,{data['trees_banner']}" class="w-full h-auto object-contain" alt="Alberi">
        </div>
      </div>

      <!-- TAB 4: ORES -->
      <div id="content-ores" class="hidden space-y-3">
        <p class="text-xs text-[#A09383]">9 Nodi di Miniera (Coal, Iron, Copper, Moon Silver, Gold, Ember, Star, Abyss, Obsidian):</p>
        <div class="rounded-xl overflow-hidden border border-[#2D2620] shadow-xl max-w-lg mx-auto">
          <img src="data:image/jpeg;base64,{data['ores_banner']}" class="w-full h-auto object-contain" alt="Minerali">
        </div>
      </div>

    </div>
  </div>

  <script>
    function showTab(tabName) {{
      const tabs = ['merchants', 'checksheet', 'trees', 'ores'];
      tabs.forEach(t => {{
        document.getElementById('content-' + t).classList.add('hidden');
        document.getElementById('tab-' + t).classList.remove('active');
      }});
      document.getElementById('content-' + tabName).classList.remove('hidden');
      document.getElementById('tab-' + tabName).classList.add('active');
    }}
  </script>
</body>
</html>"""

out_path = os.path.join(art_dir, "preview_gallery.html")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(html_content)

print(f"HTML Gallery created at: {out_path} ({len(html_content)} bytes)")
