defmodule Gru.Utils.GenFSM do

  def start_link(module, args, opts \\ []) do
    if opts[:name] do
      :gen_fsm.start_link({:local, opts[:name]}, module, args, opts)
    else
      :gen_fsm.start_link(module, args, opts)
    end
  end

  def send_event(fsm, event) do
    :gen_fsm.send_event(fsm, event)
  end

  def send_all_state_event(fsm, event) do
    :gen_fsm.send_all_state_event(fsm, event)
  end

  def sync_send_event(fsm, event, timeout \\ 5000) do
    :gen_fsm.sync_send_event(fsm, event, timeout)
  end

  def sync_send_all_state_event(fsm, event) do
    :gen_fsm.sync_send_all_state_event(fsm, event)
  end

  defmacro __using__(opts) do
    initial_state = opts[:initial_state]
    quote do
      @behaviour :gen_fsm

      def init(data) do
        {:ok, unquote(initial_state), data}
      end

      def handle_event(_event, state, data) do
        {:next_state, state, data}
      end

      def handle_sync_event(_event, _from, state, data) do
        {:reply, :ok, state, data}
      end

      def handle_info(_info, state, data) do
        {:next_state, state, data}
      end

      def terminate(reason, state, data) do
        :ok
      end

      def code_change(_old_vsn, state, data, _extra) do
        {:ok, state, data}
      end

      defoverridable [init: 1,
                      handle_event: 3,
                      handle_sync_event: 4,
                      handle_info: 3,
                      terminate: 3,
                      code_change: 4]
    end
  end

end
