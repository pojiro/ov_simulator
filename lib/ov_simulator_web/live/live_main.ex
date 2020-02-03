defmodule OvSimulatorWeb.LiveMain do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
      <h1>1d - Optimal Velocity Model Simulator</h1>
      <div class="row" phx-hook="canvases"
        data-particles=<%= Jason.encode!(@particles)%>
        data-space-size=<%= @space_size%>>
        <div class="column">
          <h2>circuit</h2>
          <canvas width="350px" height="350px" id="canvas1"></canvas>
        </div>
        <div class="column">
          <h2>limit cycle</h2>
          <canvas width="350px" height="350px" id="canvas2"></canvas>
        </div>
      </div>
      <form phx-change="change_param">
        <div class="row">
          <div class="column">
            <label for="spaceSize">space size</label>
            <input type="number" id="spaceSize" name="space_size" value=<%= @space_size %> placeholder="50" disabled>
          </div>
          <div class="column">
            <label for="particleCount">particle count</label>
            <input type="number" id="particleCount" name="particle_count" value=<%= @particle_count %> placeholder="25" disabled>
          </div>
          <div class="column">
            <label for="sensitivity">sensitivity</label>
            <input type="number" id="sensitivity" name="sensitivity" step="0.01" value=<%= @sensitivity %> placeholder="1.0" disabled>
          </div>
          <div class="column">
            <label for="stepSize">step size</label>
            <input type="number" id="stepSize" name="step_size" step="0.01" value=<%= @step_size %> placeholder="0.5" disabled>
          </div>
        </div>
      </form>
      <!--div>
        <button phx-click="start">start</button>
        <button phx-click="stop">stop</button>
      </div-->
    """
  end

  @particle_count 25
  @space_size 50
  @sensitivity 1.0
  @step_size 0.5

  def setup_particle(n) do
    %{
      position: 0.0 + n * @space_size / @particle_count,
      velocity: 0.0,
      headway: @space_size / @particle_count
    }
  end

  defp calc_headway(forward_x, x) when forward_x < x, do: forward_x - x + @space_size
  defp calc_headway(forward_x, x), do: forward_x - x

  def update_headway([h | t] = l) when is_list(l) do
    (t ++ [h])
    |> Enum.zip(l)
    |> Enum.map(fn {p_forward, p} ->
      Map.put(p, :headway, calc_headway(p_forward.position, p.position))
    end)
  end

  defp position(x) when x > @space_size, do: x - @space_size
  defp position(x), do: x

  defp ov_func(x), do: :math.tanh(x - 2.0) + :math.tanh(2.0)
  defp calc_acceleration(p), do: @sensitivity * (ov_func(p.headway) - p.velocity)
  defp calc_velocity(p), do: p.velocity

  def rk4(particles, step_size) do
    k0 =
      particles
      |> update_headway()
      |> Enum.map(fn p -> %{v: calc_velocity(p), a: calc_acceleration(p)} end)

    k1 =
      0..(Enum.count(particles) - 1)
      |> Enum.map(fn i ->
        %{
          position: position(Enum.at(particles, i).position + Enum.at(k0, i).v * step_size * 0.5),
          velocity: Enum.at(particles, i).velocity + Enum.at(k0, i).a * step_size * 0.5
        }
      end)
      |> update_headway()
      |> Enum.map(fn p -> %{v: calc_velocity(p), a: calc_acceleration(p)} end)

    k2 =
      0..(Enum.count(particles) - 1)
      |> Enum.map(fn i ->
        %{
          position: position(Enum.at(particles, i).position + Enum.at(k1, i).v * step_size * 0.5),
          velocity: Enum.at(particles, i).velocity + Enum.at(k1, i).a * step_size * 0.5
        }
      end)
      |> update_headway()
      |> Enum.map(fn p -> %{v: calc_velocity(p), a: calc_acceleration(p)} end)

    k3 =
      0..(Enum.count(particles) - 1)
      |> Enum.map(fn i ->
        %{
          position: position(Enum.at(particles, i).position + Enum.at(k2, i).v * step_size),
          velocity: Enum.at(particles, i).velocity + Enum.at(k2, i).a * step_size
        }
      end)
      |> update_headway()
      |> Enum.map(fn p -> %{v: calc_velocity(p), a: calc_acceleration(p)} end)

    0..(Enum.count(particles) - 1)
    |> Enum.map(fn i ->
      %{
        position:
          position(
            Enum.at(particles, i).position +
              (Enum.at(k0, i).v + 2.0 * Enum.at(k1, i).v + 2.0 * Enum.at(k2, i).v +
                 Enum.at(k3, i).v) /
                6.0 * step_size
          ),
        velocity:
          Enum.at(particles, i).velocity +
            (Enum.at(k0, i).a + 2.0 * Enum.at(k1, i).a + 2.0 * Enum.at(k2, i).a + Enum.at(k3, i).a) /
              6.0 * step_size
      }
    end)
    |> update_headway()
  end

  def mount(_params, _session, socket) do
    particle_count = @particle_count
    space_size = @space_size
    sensitivity = @sensitivity
    step_size = @step_size

    particles = 1..particle_count |> Enum.map(fn n -> setup_particle(n) end)
    Process.send_after(self(), :update, 100)

    {:ok,
     assign(socket,
       particles: particles,
       space_size: space_size,
       sensitivity: sensitivity,
       step_size: step_size,
       particle_count: particle_count
     )}
  end

  def handle_info(:update, %{assigns: %{particles: particles, step_size: step_size}} = socket) do
    particles = particles |> rk4(step_size)
    Process.send_after(self(), :update, 100)

    {:noreply, assign(socket, particles: particles)}
  end

  def handle_event("change_param", params, socket) do
    IO.inspect(params)
    {particle_count, _} = Integer.parse(params["particle_count"])
    {sensitivity, _} = Float.parse(params["sensitivity"])
    {space_size, _} = Integer.parse(params["space_size"])
    {step_size, _} = Float.parse(params["step_size"])

    {:noreply,
     assign(socket,
       particle_count: particle_count,
       sensitivity: sensitivity,
       space_size: space_size,
       step_size: step_size
     )}
  end

  def handle_event("start", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, socket}
  end
end
