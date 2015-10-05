defprotocol Gru.Metric.Protocol do
  def id(metric)
  def value(metric)
  def accumulate(metric, value)
end
