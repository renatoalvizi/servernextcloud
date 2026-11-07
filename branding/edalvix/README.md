# Edalvix Cloud — servidor

Camada de marca **Edalvix Cloud** sobre o Nextcloud Server. Nenhum arquivo do
núcleo é alterado: a identidade visual é aplicada pelo tema `themes/edalvix`
(ignorado pela verificação de integridade, então a assinatura oficial continua
válida e as atualizações seguem funcionando) e pelo app Theming.

Cada cliente fica em `https://<empresa>.edalvix.cloud`.

## Identidade visual

| Elemento | Valor |
| --- | --- |
| Nome | Edalvix Cloud |
| Cor primária | `#0068ce` (azul Cloud do site) |
| Fundo | `#071d33` (navy EDALVIX) |
| Slogan | Seus arquivos sempre com você |
| Ícone principal | cilindro azul do Edalvix Cloud (o mesmo do site) |
| Logos | `assets/logo.svg` (claro, para fundo navy), `assets/logo-dark.svg`, `assets/logoheader.svg` (ícone branco para o cabeçalho), `assets/favicon.svg` |
| Marca EDALVIX | secundária: assinatura "por EDALVIX" no logo e "um produto EDALVIX" no rodapé |

## Estrutura

```
branding/edalvix/
├── assets/                 logos e favicon
├── theme/                  copiado para <nextcloud>/themes/edalvix
│   ├── defaults.php        nome, cores, links e rodapé padrão
│   ├── core/img/filetypes/ ícones de pastas e tipos de arquivo no estilo do site
│   ├── core/css/           estilo do site edalvix.com.br (server.css: páginas internas; guest.css: login)
│   └── core/img/           logo e favicon do tema
├── tools/make-ui-icons.py   ícones da interface (menus, barra, ações) no estilo do site
├── tools/make-icons.py      gera os ícones (python3 branding/edalvix/tools/make-icons.py)
└── scripts/
    ├── apply-theme.sh      instala o tema numa instalação/release
    ├── build-release.sh    gera edalvix-cloud-<versão>.tar.bz2/.zip
    └── provision-tenant.sh configura a instância de um cliente
```

## Somente arquivos (padrão)

O `provision-tenant.sh` deixa ativos só os apps de arquivos:
- arquivos, compartilhamento entre os usuários da empresa, lixeira e versões;
- pré-visualização: imagens, vídeo e áudio (`viewer`), PDF (`files_pdfviewer`)
  e texto (`text`);
- segurança: política de senha, proteção contra força bruta, 2FA, login suspeito e auditoria.

Todos os outros (Atividade, Painel, Fotos, Contatos, Status, etc.) são
desativados. Para impedir que alguém instale algo:
- a loja de apps fica desligada (`appstoreenabled = false`);
- a pasta `apps/` passa a ser somente leitura (`apps_paths`);
- a atualização pela interface web fica desligada (a EDALVIX atualiza);
- o compartilhamento com outros servidores (federação) fica desligado, o que
  isola cada empresa.

**Admin da empresa:** dê a ele o papel de **administrador de grupo**
(Usuários > usuário > "Administrador de grupo"), e não de administrador geral.
Um administrador geral ainda consegue reativar, na página de Apps, os apps que
vêm no pacote. O administrador de grupo nem vê essa página.

Para manter algum app a mais: `EDALVIX_EXTRA_APPS="calendar contacts"`.
Para não aplicar a restrição: `-k`.

## Uso

### 1. Gerar o pacote do servidor

Pelo GitHub Actions: **Actions → Edalvix Cloud server package → Run workflow**,
informando a versão do Nextcloud (ex.: `32.0.1`). O artefato traz
`edalvix-cloud-<versão>.tar.bz2`, `.zip` e checksums.

Ou localmente:

```bash
bash branding/edalvix/scripts/build-release.sh 32.0.1 ./dist
```

### 2. Instância já existente

```bash
bash branding/edalvix/scripts/apply-theme.sh /var/www/nextcloud
```

### 3. Configurar o cliente `algumaempresa`

```bash
bash branding/edalvix/scripts/provision-tenant.sh -d /var/www/nextcloud algumaempresa
```

Em Docker:

```bash
OCC="docker exec -i -u www-data nextcloud php occ" bash branding/edalvix/scripts/provision-tenant.sh -d /var/www/html algumaempresa
```

Se o tema ainda não estiver em `themes/edalvix`, o script roda o
`apply-theme.sh` sozinho **antes** de alterar qualquer configuração. Os logos
são lidos de lá, então a pasta `branding/edalvix/` precisa estar no servidor.
Com `OCC=...` (Docker), rode o `apply-theme.sh` nos arquivos do Nextcloud antes.

O script configura `trusted_domains`, `overwrite.cli.url`, HTTPS, ativa o tema,
aplica nome/cores/logos via `occ theming:config`, aponta os links de download
para os clientes Edalvix e desativa os apps de anúncios e telemetria do Nextcloud
(use `-k` para mantê-los). Pode ser executado de novo sem problemas.

DNS e certificado TLS (`*.edalvix.cloud`) ficam por conta da infraestrutura.

## Testes

```bash
bash tests/edalvix/test.sh
```

## Observações

- O Nextcloud é AGPL-3.0: o código-fonte do servidor distribuído (inclusive
  este tema) deve ficar disponível para os usuários.
- A marca "Nextcloud" continua aparecendo em alguns pontos (ex.: textos de
  apps e documentação); o tema cobre a interface principal, e-mails e login.
- A integração com a versão upstream continua igual: o pipeline oficial
  (`release-*.yml`) não foi modificado.

## Workflows herdados do Nextcloud (removidos)

Este fork não usa a automação de releases do Nextcloud. Por isso foram
removidos `sync-branches.yml` (que enviava branches para
`nextcloud-releases/server`) e `release.yml`/`release-*.yml` (tag, changelog,
build, updater, milestones e calendário oficiais). Todos dependiam de
credenciais do Nextcloud e, num fork, só gerariam execuções com falha. Eles
continuam no histórico do git. Os scripts de build em `.github/scripts/` e
`tools/release/` foram mantidos, assim como os testes.
