"""
Hook oficial do MkDocs para sincronização inteligente do README.md -> docs/index.md.
Executado automaticamente em tempo de compilação (on_pre_build) garantindo
codificação UTF-8 perfeita sem Mojibake e sem necessidade de scripts manuais.
"""

import os

def on_pre_build(config):
    readme_path = "README.md"
    index_path = os.path.join(config["docs_dir"], "index.md")
    
    if os.path.exists(readme_path):
        with open(readme_path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # 1. Ajusta caminhos de imagens: docs/images/ -> images/
        content = content.replace("docs/images/", "images/")
        # 2. Ajusta links entre arquivos: (docs/ARQUITETURA.md) -> (ARQUITETURA.md)
        content = content.replace("(docs/", "(")
        # 3. Ajusta link de licença da raiz para o GitHub oficial
        content = content.replace("(LICENSE)", "(https://github.com/Luan-Diniz02/Gym_Saiyajin/blob/main/LICENSE)")
        
        with open(index_path, "w", encoding="utf-8") as f:
            f.write(content)
        
        print("[Gym Saiyajin] Sincronização inteligente README.md -> docs/index.md concluída com UTF-8.")
