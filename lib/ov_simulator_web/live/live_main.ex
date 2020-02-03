defmodule OvSimulatorWeb.LiveMain do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
      <h1>1d - Optimal Velocity Model Simulator</h1>
      <div class="row" phx-hook="canvases" data-particles=<%= Jason.encode!(@particles)%>>
        <div class="column">
          <h2>circuit</h2>
          <canvas width="350px" height="350px" id="canvas1"></canvas>
        </div>
        <div class="column">
          <h2>limit cycle</h2>
          <canvas width="350px" height="350px" id="canvas2"></canvas>
        </div>
      </div>
      <div class="row">
        <div class="column">
          <label for="spaceSize">space size</label>
          <input type="number" id="spaceSize" placeholder="50">
        </div>
        <div class="column">
          <label for="particleCount">particle count</label>
          <input type="number" id="particleCount" placeholder="25">
        </div>
        <div class="column">
          <label for="sensitivity">sensitivity</label>
          <input type="number" id="sensitivity" placeholder="1.0">
        </div>
        <div class="column">
          <label for="stepSize">step size</label>
          <input type="number" id="stepSize" placeholder="0.5">
        </div>
      </div>
      <div>
        <button phx-click="start">start</button>
        <button phx-click="stop">stop</button>
      </div>
    """
  end

  @particle_count 25
  @space_length 50
  @sensitivity 1.0

  def setup_particle(n) do
    %{
      position: 0.0 + n * @space_length / @particle_count,
      velocity: 0.0,
      headway: @space_length / @particle_count
    }
  end

  defp move_particle(%{position: x} = p) do
    %{position: position(x + 1), velocity: 0.0}
  end

  def update_headway([h | t] = l) when is_list(l) do
    (t ++ [h])
    |> Enum.zip(l)
    |> Enum.map(fn {p_forward, p} ->
      Map.put(p, :headway, calc_headway(p_forward.position, p.position))
    end)
  end

  defp position(x) when x > @space_length, do: x - @space_length
  defp position(x), do: x

  defp ov_func(x), do: :math.tanh(x - 2.0) + :math.tanh(2.0)
  defp calc_acceleration(p), do: @sensitivity * (ov_func(p.headway) - p.velocity)
  defp calc_velocity(p), do: p.velocity

  defp calc_headway(forward_x, x) when forward_x < x, do: forward_x - x + @space_length
  defp calc_headway(forward_x, x), do: forward_x - x

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

  defp integrate(current_value, step_size, fun, args \\ []) do
    k0 = fun.(current_value)
    k1 = fun.(current_value + k0 * step_size * 0.5)
    k2 = fun.(current_value + k1 * step_size * 0.5)
    k3 = fun.(current_value + k2 * step_size)

    current_value + (k0 + 2.0 * k1 + 2.0 * k2 + k3) / 6.0 * step_size
  end

  def mount(_params, _session, socket) do
    particles = 1..@particle_count |> Enum.map(fn n -> setup_particle(n) end)
    Process.send_after(self(), :update, 100)
    {:ok, assign(socket, particles: particles)}
  end

  def handle_info(:update, %{assigns: %{particles: particles}} = socket) do
    particles = particles |> rk4(0.5)
    Process.send_after(self(), :update, 100)

    {:noreply, assign(socket, particles: particles)}
  end

  def handle_event("start", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, socket}
  end
end
