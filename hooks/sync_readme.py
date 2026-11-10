"""
Hook oficial do MkDocs para sincronização inteligente do README.md -> docs/index.md.
Executado automaticamente em tempo de compilação (on_pre_build) garantindo
codificação UTF-8 perfeita sem Mojibake e sem necessidade de scripts manuais.
"""

import os
import re

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
        
        # 4. Remove auto-referência na Home do portal (banner redundante "Acessar Portal Web" quando já se está no portal)
        redundant_portal_block = re.compile(
            r'<p align="center">\s*<a href="https://luan-diniz02\.github\.io/Gym_Saiyajin/">.*?</a>\s*</p>\s*'
            r'> 🌐 \*\*Portal Interativo Online\*\*:.*?\n\n',
            re.DOTALL
        )
        welcome_callout = (
            "> 🥋 **Portal de Engenharia & Documentação Técnica**: Explore as camadas da arquitetura offline-first, "
            "o design system vetorial no Canvas do Flutter, a matemática da progressão de Ki e a telemetria esportiva "
            "navegando pelas abas superiores ou pela busca instantânea.\n\n"
        )
        content = redundant_portal_block.sub(welcome_callout, content)

        # 5. Remove o badge redundante de Docs apontando para o próprio portal no hero da index
        docs_badge_pattern = re.compile(
            r'\s*<a href="https://luan-diniz02\.github\.io/Gym_Saiyajin/"><img [^>]*badge/Docs-MkDocs[^>]*></a>'
        )
        content = docs_badge_pattern.sub('', content)

        with open(index_path, "w", encoding="utf-8") as f:
            f.write(content)
        
        print("[Gym Saiyajin] Sincronização inteligente README.md -> docs/index.md concluída com UTF-8.")
