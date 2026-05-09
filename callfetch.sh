#!/usr/bin/env zsh

# fastfetch起動条件の設定（連想配列）
typeset -A FASTFETCH_CONDITIONS=(
  [min_width]=$((FASTFETCH_WIDTH + 50))                    # 最小横幅
  [require_interactive]=false        # インタラクティブシェル必須
  [require_command]=true            # fastfetchコマンド存在確認
  [check_ps1]=false                  # PS1環境変数の確認
  [exclude_neovim]=true             # neovim上での起動を除外
)

# スクリプトが実行されたかどうかのフラグ
SCRIPT_EXECUTED=0
# fastfetchが実行されたかどうかのフラグ
FASTFETCH_EXECUTED=0

# 条件チェック関数
check_conditions() {
  local term_width=${COLUMNS:-0}

  # 横幅チェック
  if [[ ${FASTFETCH_CONDITIONS[min_width]} -gt 0 ]] && [[ $term_width -lt ${FASTFETCH_CONDITIONS[min_width]} ]]; then
    # echo "width check faild."
    return 1
  fi

  # インタラクティブシェルチェック
  if [[ ${FASTFETCH_CONDITIONS[require_interactive]} == "true" ]] && ! [[ -o interactive ]]; then
    # echo "interactive check faild."
    return 1
  fi

  # PS1環境変数チェック
  if [[ ${FASTFETCH_CONDITIONS[check_ps1]} == "true" ]] && [[ -z "$PS1" ]]; then
    # echo "ps1 check faild."
    return 1
  fi

  # neovim上での起動チェック
  if [[ ${FASTFETCH_CONDITIONS[exclude_neovim]} == "true" ]]; then
    # NVIM環境変数またはVIMランタイム環境変数をチェック
    if [[ -n "$NVIM" ]] || [[ -n "$NVIM_LISTEN_ADDRESS" ]] || [[ "$VIM" == *"nvim"* ]]; then
      # echo "vim/nvim runtime detected."
      return 1
    fi
  fi

  # fastfetchコマンド存在チェック
  if [[ ${FASTFETCH_CONDITIONS[require_command]} == "true" ]] && ! command -v fastfetch >/dev/null 2>&1; then
      # echo "fastfetch command check faild."
      return 1
  fi

  # echo "condition check succeed!"
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
    fastfetch ${FASTFETCH_TYPE:+--$FASTFETCH_TYPE} "$FASTFETCH_SOURCE" --echo-width "$FASTFETCH_WIDTH" --logo-padding-left "$FASTFETCH_PADDING_LEFT" --logo-padding-right "$FASTFETCH_PADDING_RIGHT" --logo-padding-top "$FASTFETCH_PADDING_TOP"
    FASTFETCH_EXECUTED=1
    SCRIPT_EXECUTED=1
  else
    # echo "error occurred"
  fi
}

# ウィンドウサイズ変更の監視を開始
trap handle_resize WINCH

autoload -Uz add-zsh-hook
add-zsh-hook precmd call
