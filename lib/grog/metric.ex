defprotocol Grog.Metric do
  def id(metric)
  def value(metric)
  def accumulate(metric, value)
end
