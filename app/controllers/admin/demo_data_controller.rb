module Admin
  class DemoDataController < ApplicationController
    DEMO_DATA_PIN = "1234".freeze
    PIN_SESSION_KEY = :demo_data_admin_granted

    before_action :require_pin_grant!, except: %i[index authenticate]

    def index
      @pin_required = !pin_granted?
      @summary = DemoData::Manager.summary unless @pin_required
    end

    def authenticate
      if secure_pin_match?(demo_data_pin)
        session[PIN_SESSION_KEY] = true
        redirect_to admin_demo_data_path, notice: "デモデータ管理を解除しました。"
      else
        redirect_to admin_demo_data_path, alert: "PINが正しくありません。"
      end
    end

    def relock
      clear_pin_grant!
      redirect_to admin_demo_data_path, notice: "デモデータ管理をロックしました。"
    end

    def create
      DemoData::Manager.generate!(seed: optional_seed, label: "追加デモバッチ")
      redirect_to admin_demo_data_path, notice: "ランダムなデモデータを追加しました。"
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      redirect_to admin_demo_data_path, alert: "デモデータを追加できませんでした: #{error.message}"
    end

    def reset
      return redirect_without_confirmation unless confirmed?

      DemoData::Manager.reset!(seed: optional_seed)
      redirect_to admin_demo_data_path, notice: "デモデータを基準状態へ戻しました。"
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      redirect_to admin_demo_data_path, alert: "デモデータを基準状態へ戻せませんでした: #{error.message}"
    end

    def destroy
      return redirect_without_confirmation unless confirmed?

      DemoData::Manager.cleanup!
      redirect_to admin_demo_data_path, notice: "生成したデモデータだけを削除しました。"
    rescue ActiveRecord::RecordInvalid => error
      redirect_to admin_demo_data_path, alert: "デモデータを削除できませんでした: #{error.message}"
    end

    private

    def demo_data_pin
      params.expect(demo_data: [ :pin ]).fetch(:pin).to_s
    rescue ActionController::ParameterMissing
      ""
    end

    def secure_pin_match?(pin)
      ActiveSupport::SecurityUtils.secure_compare(pin.to_s, DEMO_DATA_PIN)
    rescue ArgumentError
      false
    end

    def pin_granted?
      session[PIN_SESSION_KEY] == true
    end

    def require_pin_grant!
      return if pin_granted?

      clear_pin_grant!
      redirect_to admin_demo_data_path,
        alert: "デモデータ管理を利用するにはPINの入力が必要です。"
    end

    def clear_pin_grant!
      session.delete(PIN_SESSION_KEY)
    end

    def confirmed?
      params[:confirm].to_s == "1"
    end

    def redirect_without_confirmation
      redirect_to admin_demo_data_path,
        alert: "実行する場合は確認チェックボックスを選択してください。"
    end

    def optional_seed
      value = params[:seed].to_s.strip
      return if value.empty?
      return Integer(value, 10) if value.match?(/\A\d+\z/)

      raise ArgumentError, "シードは整数で指定してください"
    end
  end
end
