#!/bin/zsh

# fastfetch起動条件の設定（連想配列）
typeset -A FASTFETCH_CONDITIONS=(
    [min_width]=85                    # 最小横幅
    [require_interactive]=true        # インタラクティブシェル必須
    [require_command]=true            # fastfetchコマンド存在確認
    [check_ps1]=true                  # PS1環境変数の確認
    [exclude_neovim]=true             # neovim上での起動を除外
)

# スクリプトが実行されたかどうかのフラグ
SCRIPT_EXECUTED=0
# fastfetchが実行されたかどうかのフラグ
FASTFETCH_EXECUTED=0

# 条件チェック関数
check_conditions() {
  local term_width=$(tput cols)

  # 横幅チェック
  if [[ ${FASTFETCH_CONDITIONS[min_width]} -gt 0 ]] && [[ $term_width -lt ${FASTFETCH_CONDITIONS[min_width]} ]]; then
    return 1
  fi

  # インタラクティブシェルチェック
  if [[ ${FASTFETCH_CONDITIONS[require_interactive]} == "true" ]] && [[ $- != *i* ]]; then
    return 1
  fi

  # PS1環境変数チェック
  if [[ ${FASTFETCH_CONDITIONS[check_ps1]} == "true" ]] && [[ -z "$PS1" ]]; then
    return 1
  fi

  # neovim上での起動チェック
  if [[ ${FASTFETCH_CONDITIONS[exclude_neovim]} == "true" ]]; then
    # NVIM環境変数またはVIMランタイム環境変数をチェック
    if [[ -n "$NVIM" ]] || [[ -n "$NVIM_LISTEN_ADDRESS" ]] || [[ "$VIM" == *"nvim"* ]]; then
      return 1
    fi

    # 親プロセスがneovimかチェック
    local parent_cmd=$(ps -p $PPID -o comm= 2>/dev/null)
    if [[ "$parent_cmd" == *"nvim"* ]]; then
      return 1
    fi
  fi

  # fastfetchコマンド存在チェック
  if [[ ${FASTFETCH_CONDITIONS[require_command]} == "true" ]] && ! command -v fastfetch >/dev/null 2>&1; then
      return 1
  fi

  return 0
}

# SIGWINCH（ウィンドウサイズ変更）シグナルハンドラ
handle_resize() {
  local current_width=$(tput cols)

  # fastfetchが実行されていて、かつ横幅が最小値を下回った場合
  if [[ $FASTFETCH_EXECUTED -eq 1 ]] && [[ $current_width -lt ${FASTFETCH_CONDITIONS[min_width]} ]]; then
    clear
    # echo "Terminal width too narrow for fastfetch display. Screen cleared."

    # 監視を停止
    trap - WINCH

    # プロンプトを再表示
    zle reset-prompt
    # スクリプト終了（通常のシェル状態に戻る）
    return 0
  fi
}

# メイン処理
call() {
  if check_conditions && [[ $SCRIPT_EXECUTED -eq 0 ]]; then
    fastfetch
    FASTFETCH_EXECUTED=1
    SCRIPT_EXECUTED=1
  fi
}

# ウィンドウサイズ変更の監視を開始
trap handle_resize WINCH

autoload -Uz add-zsh-hook
add-zsh-hook precmd call
