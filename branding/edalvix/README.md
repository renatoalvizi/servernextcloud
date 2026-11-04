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
| Logos | `assets/logo.svg` (claro, para fundo navy), `assets/logo-dark.svg`, `assets/logoheader.svg`, `assets/favicon.svg` |

## Estrutura

```
branding/edalvix/
├── assets/                 logos e favicon
├── theme/                  copiado para <nextcloud>/themes/edalvix
│   ├── defaults.php        nome, cores, links e rodapé padrão
│   └── core/img/           logo e favicon do tema
└── scripts/
    ├── apply-theme.sh      instala o tema numa instalação/release
    ├── build-release.sh    gera edalvix-cloud-<versão>.tar.bz2/.zip
    └── provision-tenant.sh configura a instância de um cliente
```

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
OCC="docker exec -u www-data nextcloud php occ" bash branding/edalvix/scripts/provision-tenant.sh -d /var/www/html algumaempresa
```

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
