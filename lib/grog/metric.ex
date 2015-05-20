defprotocol Grog.Metric do
  def name(metric)
  def value(metric)
  def accumulate(metric, value)
end
